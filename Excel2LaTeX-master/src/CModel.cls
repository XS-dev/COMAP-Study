VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CModel"
Attribute VB_Base = "0{FCFB3D2A-A0FA-1068-A738-08002B3371B5}"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_TemplateDerived = False
Attribute VB_Customizable = False
Option Explicit

Implements IModel

Dim sb As StringBuilder
Dim CellWidth As Integer    'Characters per Cell in output file
Dim convertDollar As Boolean
Dim booktabs As Boolean
Dim tableFloat As Boolean
Dim Indent As Integer
Dim sFileName As String
Dim RangeToUse As Range

Private mpEvents As New IModelEvents

Private Sub Class_Initialize()
    Set sb = New StringBuilder
End Sub

' IModel implementation

Public Property Get IModel_Events() As IModelEvents
    Set IModel_Events = mpEvents
End Property

Public Property Get IModel_Options() As x2lOptions
    If convertDollar Then IModel_Options = IModel_Options Or x2lConvertMathChars
    If booktabs Then IModel_Options = IModel_Options Or x2lBooktabs
    If tableFloat Then IModel_Options = IModel_Options Or x2lCreateTableEnvironment
End Property
Public Property Let IModel_Options(ByVal Options As x2lOptions)
    Dim oldOptions As x2lOptions
    oldOptions = IModel_Options()
    
    convertDollar = (Options And x2lConvertMathChars) <> x2lNone
    booktabs = (Options And x2lBooktabs) <> x2lNone
    tableFloat = (Options And x2lCreateTableEnvironment) <> x2lNone
    
    If oldOptions <> IModel_Options() Then
        mpEvents.RaiseChanged
    End If
End Property

Public Property Get IModel_Indent() As Integer
    IModel_Indent = Indent
End Property
Public Property Let IModel_Indent(ByVal iIndent As Integer)
    If Indent = iIndent Then Exit Property
    Indent = iIndent
    mpEvents.RaiseChanged
End Property

Public Property Get IModel_CellWidth() As Integer
    IModel_CellWidth = CellWidth
End Property
Public Property Let IModel_CellWidth(ByVal iCellWidth As Integer)
    If CellWidth = iCellWidth Then Exit Property
    CellWidth = iCellWidth
    mpEvents.RaiseChanged
End Property

Public Property Get IModel_FileName() As String
    IModel_FileName = sFileName
End Property
Public Property Let IModel_FileName(ByVal iFileName As String)
    Dim sBaseDir As String
    sBaseDir = WorksheetDir
    If UCase(iFileName) Like UCase(sBaseDir) & "\*" Then
        iFileName = Mid$(iFileName, Len(sBaseDir) + 2)
    End If
    sFileName = iFileName
End Property
Public Property Get IModel_AbsoluteFileName() As String
    If sFileName Like "?:\*" Or sFileName Like "\\*\*" Then
        IModel_AbsoluteFileName = sFileName
    Else
        IModel_AbsoluteFileName = Printf("%1\%2", WorksheetDir, sFileName)
    End If
End Property

Public Property Get IModel_RangeAddress() As String
    IModel_RangeAddress = RangeToAddress(RangeToUse)
End Property
Public Property Let IModel_RangeAddress(ByVal iRange As String)
    Set RangeToUse = AddressToRange(iRange)
    mpEvents.RaiseChanged
End Property

Public Function IModel_GetConversionResult() As String
    Dim r As Range, rc As Range, c As Range
    Dim FileName As String
    Dim i As Integer
    Dim j As Integer
    Dim pos As Integer
    
    Set sb = New StringBuilder
    If RangeToUse Is Nothing Then
        AddText "% Error: No range selected.", True
        GoTo leave
    End If
    AddText Space(Indent) + "% Table generated by Excel2LaTeX from sheet '" + RangeToUse.Worksheet.Name + "'", True
    
    If tableFloat Then
        AddText Space(Indent) + "\begin{table}[htbp]", True
        Indent = Indent + 2
        AddText Space(Indent) + "\centering", True
        AddText Space(Indent) + "\caption{Add caption}", True
        Indent = Indent + 2
    End If
    
    AddText Space(Indent) + "\begin{tabular}{"
    AddText GetColumnsFormat(RangeToUse)
    AddText "}", True
      
    'Start checking top border
    Set r = RangeToUse.Rows(1)
    
    AddText HorizontalBorder(r, Indent, Top:=True)
    
    'Table contents:
    For j = 1 To RangeToUse.Rows.Count ' for each row
        Set r = RangeToUse.Rows(j)
        Set rc = r.Cells
        AddText Space(Indent)
        Indent = Indent + 2
    
        Dim RowColor&
        RowColor = GetRowColor(rc)
        If RowColor <> &HFFFFFF Then AddText Printf("\rowcolor[rgb]{%1} ", ColorToRGB(RowColor))
        For i = 1 To rc.Count  ' for each cell in row r
            Set c = rc.Item(i)
            i = i + AddCell(c, i = 1, i + c.MergeArea.Columns.Count > rc.Count, RowColor) - 1
        Next i 'cells in row
        
        ' Struts and end of line
        AddText Printf("%1\\", GetStruts(r)), True
        Indent = Indent - 2
        
        ' Check for Border lines
        AddText HorizontalBorder(r.Offset(RowOffset:=1), Indent, Bottom:=j = RangeToUse.Rows.Count)
    Next j 'row
    
theend:      'Tabellenende
    AddText Space(Indent) + "\end{tabular}%", True
    
    If tableFloat Then
        Indent = Indent - 2
        AddText Space(Indent) + "\label{tab:addlabel}%", True
        Indent = Indent - 2
        AddText Space(Indent) + "\end{table}%", True
    End If
    
leave:
    IModel_GetConversionResult = sb.ToString()
    
    ' Save to registry after successful conversion
    SaveToRegistry
End Function

Public Sub IModel_InitDefault()
    Indent = 0
    CellWidth = 5
    IModel_Options = x2lBooktabs Or x2lConvertMathChars Or x2lCreateTableEnvironment
    
    InitFromRegistry

    Set RangeToUse = GetDefaultRange
    sFileName = GetDefaultFileName
End Sub

Private Property Get IModel_Description() As String
    If RangeToUse Is Nothing Then
        IModel_Description = "(empty range)"
        Exit Property
    End If
    IModel_Description = Printf("%1: %2", Me.IModel_RangeAddress, Me.IModel_FileName)
End Property

Private Property Get IModel_Range() As Range
    Set IModel_Range = RangeToUse
End Property
Private Property Set IModel_Range(ByVal pRange As Range)
    Set RangeToUse = pRange.Areas(1)
    mpEvents.RaiseChanged
End Property

' Class implementation

Private Function GetRowColor(Row As Range) As Long
    GetRowColor = RangeOrDisplayFormat(Row).Interior.Color
    If GetRowColor <> 0 Then Exit Function
    GetRowColor = RangeOrDisplayFormat(Row.Cells(1, 1)).Interior.Color
End Function

Private Sub InitFromRegistry()
    On Error Resume Next
    StringToModel Me, VBA.GetSetting("Excel2LaTeX", "Main", "DefaultSettings")
End Sub

Private Sub SaveToRegistry()
    On Error Resume Next
    VBA.SaveSetting "Excel2LaTeX", "Main", "DefaultSettings", ModelToString(Me)
End Sub

Private Function WorksheetDir() As String
    If RangeToUse Is Nothing Then
        WorksheetDir = "."
        Exit Function
    End If
    
    WorksheetDir = RangeToUse.Worksheet.Parent.PATH
End Function

Private Function GetDefaultRange() As Range
    If Selection Is Nothing Then Exit Function
    If Not TypeOf Selection Is Range Then Exit Function
    If Selection.Count = 1 Then
        Set GetDefaultRange = Selection.CurrentRegion
    Else
        Set GetDefaultRange = Selection
    End If
End Function

Private Function GetDefaultFileName()
    Dim sName As String
    On Error Resume Next
    sName = ActiveSheet.Name
    sName = RangeToUse.Name.Name
    On Error GoTo 0
    GetDefaultFileName = Printf("%1.tex", sName)
End Function

Private Sub AddText(ByVal txt As String, Optional ByVal LineFeed = False)
    sb.Append txt
    If LineFeed Then sb.Append vbLf
End Sub

Private Function PadSpace(ByVal n As Long)
    PadSpace = Space(Application.WorksheetFunction.Max(0, n))
End Function

Private Function GetStruts(ByVal rRow As Range) As String
    Debug.Assert rRow.Rows.Count = 1
    
    ' No struts in booktabs mode
    If booktabs Then Exit Function
    
    Dim bHasTopBorder As Boolean
    Dim bHasBottomBorder As Boolean
    
    bHasTopBorder = HasHorizontalBorder(rRow)
    bHasBottomBorder = HasHorizontalBorder(rRow.Offset(RowOffset:=1))
    
    If bHasTopBorder Then
        If bHasBottomBorder Then
            GetStruts = "\bigstrut"
        Else
            GetStruts = "\bigstrut[t]"
        End If
    Else
        If bHasBottomBorder Then
            GetStruts = "\bigstrut[b]"
        End If
    End If
End Function

Private Function GetColumnsFormat(ByVal RangeToUse As Range, Optional ByVal bSkipFirst = False, Optional ByVal lStep As Long = 1) As String
    Dim rc As Range, c As Range, cn As Range
    
    Dim i As Long
    Dim stg As String
    
    Set rc = RangeToUse.Columns
    Set cn = rc.Item(1)
    
    If Not bSkipFirst Then
        stg = VerticalBorder(cn)
    End If
    
    For i = 1 To rc.Count Step lStep
        Set c = cn
        Set cn = Nothing
        On Error Resume Next
        Set cn = rc(i + lStep)
        On Error GoTo 0
        Dim HorizontalAlignment
        'get horizontal alignment using the last row of the table
        HorizontalAlignment = RangeOrDisplayFormat(c.Cells(c.Rows.Count, 1)).HorizontalAlignment
        If VarType(c.Cells(c.Rows.Count, 1).Value2) = vbString And c.Cells(c.Rows.Count, 1).WrapText Then
            If RangeToUse.MergeCells Then
                stg = stg + "p{" & LTrim$(Str$(0.5 * SumColumnWidths(RangeToUse))) & "em}"
            Else
                stg = stg + "p{" & LTrim$(Str$(0.5 * c.ColumnWidth)) & "em}"
            End If
        Else
            Select Case HorizontalAlignment
            Case xlLeft
                stg = stg + "l"
            Case xlCenter
                stg = stg + "c"
            Case xlGeneral
                stg = stg + IIf(VarType(c.Cells(c.Rows.Count, 1).Value2) = vbString, "l", "r")
            Case Else
                stg = stg + "r" 'Default alignment is right
            End Select
        End If
        If Not (cn Is Nothing) Then
            stg = stg + VerticalBorder(cn)
        End If
    Next i
    GetColumnsFormat = stg
End Function

Private Function SumColumnWidths(r As Range) As Double
    Dim col As Range
    For Each col In r
        SumColumnWidths = SumColumnWidths + col.ColumnWidth
    Next
End Function

Private Function VerticalBorder(ByVal pRightRange As Range)
    'return nothing, | or ||
    Dim stg As String
    Select Case VerticalBorderStyle(pRightRange)
    Case xlDouble
        stg = "||"
    Case xlContinuous
        stg = "|"
    Case Else
        stg = ""
    End Select
    VerticalBorder = stg
End Function

Private Function VerticalBorderStyle(ByVal pRightRange As Range) As Variant
    VerticalBorderStyle = xlNone
    
    Dim pRightRow As Range
    Dim pLeftRow As Range
    Set pRightRow = pRightRange.Cells(pRightRange.Rows.Count, 1)
    VerticalBorderStyle = ResolveLine(VerticalBorderStyle, RangeOrDisplayFormat(pRightRow).Borders(xlLeft).LineStyle)
    
    If pRightRow.Column > 1 Then
        Set pLeftRow = pRightRow.Resize(ColumnSize:=1).Offset(ColumnOffset:=-1)
        
        VerticalBorderStyle = ResolveLine(VerticalBorderStyle, RangeOrDisplayFormat(pLeftRow).Borders(xlRight).LineStyle)
    End If
End Function

Private Function HasHorizontalBorder(ByVal rBelowRange As Range) As Boolean
    HasHorizontalBorder = (HorizontalBorder(rBelowRange, 0) <> "")
End Function

Private Function HorizontalBorder(ByVal rBelowRange As Range, ByVal spaces As Integer, Optional ByVal Top As Boolean, Optional ByVal Bottom As Boolean) As String
    Debug.Assert rBelowRange.Rows.Count = 1
    
    Dim rAboveRange As Range
    If rBelowRange.Row > 1 Then
        Set rAboveRange = rBelowRange.Offset(RowOffset:=-1)
    End If
    
    Dim sRangeDef As String
    Dim lLineOpenFrom As Long
    Dim bOpenLine As Boolean
    Dim borderStyle As Variant
    
    Dim rBelowColumn As Range
    Dim rAboveColumn As Range
    For Each rBelowColumn In rBelowRange.Columns
        If Not rAboveRange Is Nothing Then
            Set rAboveColumn = rAboveRange.Columns(rBelowColumn.Column - rBelowRange.Column + 1)
        End If
        
        If Not IsFirstRowOfMultiRowCell(rBelowColumn) Then
            bOpenLine = False
        Else
            borderStyle = ResolveHorizontalLine(rBelowColumn, rAboveColumn)
            bOpenLine = (borderStyle <> xlNone)
        End If
        
        AppendToRangeSet sRangeDef, lLineOpenFrom, bOpenLine, rBelowColumn.Column - rBelowRange.Column + 1
    Next
    
    AppendToRangeSet sRangeDef, lLineOpenFrom, False, rBelowRange.Columns.Count + 1
    
    Dim HLineCmd$, CLineCmd$, MoreCLineCmd$
    If booktabs Then
        If Top Then
            HLineCmd = "\toprule"
        ElseIf Bottom Then
            HLineCmd = "\bottomrule"
        Else
            HLineCmd = "\midrule"
        End If
    Else
        HLineCmd = "\hline"
    End If
    CLineCmd = IIf(booktabs, "\cmidrule", "\cline")
    MoreCLineCmd = IIf(booktabs, "\morecmidrules", "")
    
    ' Straight line? => revert to old behavior
    If sRangeDef = Printf("1-%1", rBelowRange.Columns.Count) Then
        'return nothing, \hline or \hline\hline
        borderStyle = ResolveHorizontalLine(rBelowRange, rAboveRange)
    
        Select Case borderStyle
        Case xlDouble
            HorizontalBorder = Space(spaces) + HLineCmd + vbLf + Space(spaces) + HLineCmd + vbLf
        Case xlContinuous
            HorizontalBorder = Space(spaces) + HLineCmd + vbLf
        Case Else
            HorizontalBorder = ""
        End Select
    ElseIf sRangeDef = "" Then
        HorizontalBorder = ""
    Else
        HorizontalBorder = Printf(CLineCmd + "{%1}", Replace(sRangeDef, ";", "}" + CLineCmd + "{"))
    End If
End Function

Public Sub AppendToRangeSet(ByRef sRangeDef As String, ByRef lLineOpenFrom As Long, ByVal bOpenLine As Boolean, ByVal lCurrentPos As Long)
    If bOpenLine Then
        If lLineOpenFrom <= 0 Then
            lLineOpenFrom = lCurrentPos
            sRangeDef = Printf("%1%3%2", sRangeDef, lCurrentPos, IIf(sRangeDef = "", "", ";"))
        End If
    Else
        If lLineOpenFrom > 0 Then
            sRangeDef = Printf("%1-%2", sRangeDef, lCurrentPos - 1)
            lLineOpenFrom = 0
        End If
    End If
End Sub

Private Function ResolveHorizontalLine(ByVal rBelowRange As Range, ByVal rAboveRange As Range)
    ResolveHorizontalLine = RangeOrDisplayFormat(rBelowRange).Borders(xlTop).LineStyle
    If rAboveRange Is Nothing Then Exit Function
    ResolveHorizontalLine = ResolveLine(ResolveHorizontalLine, RangeOrDisplayFormat(rAboveRange).Borders(xlBottom).LineStyle)
End Function

Private Function ResolveLine(ByVal line1, ByVal line2)
    ResolveLine = xlNone
    If line1 = xlContinuous Or line2 = xlContinuous Then ResolveLine = xlContinuous
    If line1 = xlDouble Or line2 = xlDouble Then ResolveLine = xlDouble
End Function

Private Function AddCell(ByVal rCell As Range, ByVal bFirstCell As Boolean, ByVal bLastCell As Boolean, ByVal RowColor&) As Long
    Dim txt As String
    Dim nColumns As Long
    Dim nRows As Long
    
    txt = FormatCell(rCell, RowColor)
    
    Dim bRequiresDifferentVlineFormat As Boolean
    bRequiresDifferentVlineFormat = RequiresDifferentVlineFormat(rCell)
    
    'Check for multicolumns
    If rCell.MergeCells Or bRequiresDifferentVlineFormat Then   'multicolumn cell
        With rCell.MergeArea
            nColumns = .Columns.Count
            nRows = .Rows.Count
        End With
        
        If nRows > 1 Then
            ' Add contents only for first row of a multi-row cell
            If IsFirstRowOfMultiRowCell(rCell) Then
                txt = Printf("\multirow{%1}[%3]{*}{%2}", nRows, txt, GetMultiRowStruts(rCell))
            Else
                txt = ""
            End If
        End If
        If (nColumns > 1) Or bRequiresDifferentVlineFormat Then
            txt = Printf("\multicolumn{%1}{%2}{%3}", _
                nColumns, _
                GetColumnsFormat(rCell.MergeArea, Not bFirstCell, rCell.MergeArea.Columns.Count), _
                txt)
        End If
    Else 'single cell
        nColumns = 1
        nRows = 1
    End If
    
    AddText txt
    If Not bLastCell Then
        If CellWidth > 0 Then
            AddText PadSpace(nColumns * (3 + CellWidth) - 3 - Len(txt))
        End If
        AddText " &"
    End If
    If CellWidth > 0 Then
        AddText " "
    Else
        AddText vbLf & Space(Indent)
    End If
    
    AddCell = nColumns
End Function

Private Function FormatCell(ByVal rCell As Range, ByVal RowColor&) As String
    FormatCell = rCell.Text
    
    If Len(FormatCell) > 0 Then
        FormatCell = ConvertSpecialChars(FormatCell, isnumeric(rCell.Value2))
        FormatCell = FormatCellFont(FormatCell, rCell)
        FormatCell = FormatCellOrientation(FormatCell, rCell)
    End If
    FormatCell = FormatCellColor(FormatCell, rCell, RowColor)
End Function

Private Function FormatCellColor(Text$, Cell As Range, ByVal RowColor&) As String
    Dim FontColor&, InteriorColor&
    FontColor = ZeroIfNull(RangeOrDisplayFormat(cell).Font.Color)
    InteriorColor = RangeOrDisplayFormat(cell).Interior.Color
    
    If FontColor = 0 Then
        FormatCellColor = Text
    Else
        FormatCellColor = Printf("\textcolor[rgb]{%1}{%2}", ColorToRGB(FontColor), Text)
    End If
    
    If InteriorColor <> RowColor Then FormatCellColor = Printf("\cellcolor[rgb]{%1}", _
            ColorToRGB(InteriorColor)) & FormatCellColor
End Function

Private Function ColorToRGB(ByVal Color&) As String
    ColorToRGB = Printf("%1, %2, %3", Str$(Round((Color And &HFF&) / 255, 3)), _
                Str$(Round((Color And &HFF00&) / &H100 / 255, 3)), _
                Str$(Round((Color And &HFF0000) / &H10000 / 255, 3)))
End Function

Private Function ConvertSpecialChars(ByVal sText As String, ByVal Number As Boolean) As String
    ConvertSpecialChars = sText
    
    'Check for special characters - always convert if numeric
    If convertDollar Or Number Then
        ConvertSpecialChars = Replace(ConvertSpecialChars, "\", "\textbackslash{}")
        ConvertSpecialChars = Replace(ConvertSpecialChars, "$", "\$")
        ConvertSpecialChars = Replace(ConvertSpecialChars, "_", "\_")
        ConvertSpecialChars = Replace(ConvertSpecialChars, "^", "\^")
    End If
    ConvertSpecialChars = Replace(ConvertSpecialChars, "%", "\%")
    ConvertSpecialChars = Replace(ConvertSpecialChars, "&", "\&")
    ConvertSpecialChars = Replace(ConvertSpecialChars, "#", "\#")
    ConvertSpecialChars = Replace$(ConvertSpecialChars, vbLf, "\newline{}")
End Function

Private Function FormatCellFont(ByVal sText As String, ByVal rCell As Range) As String
    Dim pFont As Font
    Set pFont = RangeOrDisplayFormat(rCell).Font
    
    FormatCellFont = sText
    
    'Check for Font Styles
    If pFont.Bold Then FormatCellFont = Printf("\textbf{%1}", FormatCellFont)
    If pFont.Italic Then FormatCellFont = Printf("\textit{%1}", FormatCellFont)
    
    'Typeset math in bold if required
    If Not pFont.Bold Then
    ElseIf convertDollar Then
    ElseIf InStr(1, FormatCellFont, "$") > 0 Then
        FormatCellFont = Printf("\boldmath{}%1\unboldmath{}", FormatCellFont)
    End If
End Function

Private Function FormatCellOrientation(ByVal sText As String, ByVal rCell As Range) As String
    ' Requires "rotating" package
    FormatCellOrientation = sText
    
    Dim Orientation
    Orientation = RangeOrDisplayFormat(rCell).Orientation
    
    ' Check for orientation
    Select Case Orientation
    Case xlHorizontal
        ' Do nothing
        
    Case xlUpward
        FormatCellOrientation = Printf("\begin{sideways}%1\end{sideways}", FormatCellOrientation)
        
    Case xlDownward
        FormatCellOrientation = Printf("\begin{turn}{-90}%1\end{turn}", FormatCellOrientation)
        
    Case Else
        FormatCellOrientation = Printf("\begin{turn}{%2}%1\end{turn}", FormatCellOrientation, rCell.Orientation)
    
    End Select
End Function

Private Function RequiresDifferentVlineFormat(ByVal rCell As Range) As Boolean
    Dim sColumnFormat As String
    Dim sCellFormat As String
    
    Dim lRelativeColumn As Long
    lRelativeColumn = GetRelativeColumn(rCell)
    
    Dim rColumn As Range
    Set rColumn = RangeToUse.Columns(lRelativeColumn)
    
    sColumnFormat = GetColumnsFormat(rColumn, lRelativeColumn > 1, rCell.MergeArea.Columns.Count)
    sCellFormat = GetColumnsFormat(rCell, lRelativeColumn > 1, rCell.MergeArea.Columns.Count)
    
    If IsEmpty(rCell.Value2) Then
        ' if the cell is empty, ignore alignment changes and only change the vline format
        ' if a vline was added or removed
        RequiresDifferentVlineFormat = (Len(sColumnFormat) <> Len(sCellFormat))
    Else
        RequiresDifferentVlineFormat = (sColumnFormat <> sCellFormat)
    End If
End Function

Private Function GetRelativeColumn(ByVal rCell As Range) As Long
    GetRelativeColumn = rCell.Column - RangeToUse.Column + 1
End Function

Private Function GetRelativeRow(ByVal rCell As Range) As Long
    GetRelativeRow = rCell.Row - RangeToUse.Row + 1
End Function

Function IsFirstRowOfMultiRowCell(ByVal rCell As Range) As Boolean
    IsFirstRowOfMultiRowCell = (rCell.Row = rCell.MergeArea.Row)
End Function

Function GetMultiRowStruts(ByVal rCell As Range) As Long
    Dim lStartRow As Long
    Dim lEndRow As Long
    Dim lRow As Long
    Dim bBorder As Boolean
    
    lStartRow = GetRelativeRow(rCell)
    lEndRow = lStartRow + rCell.MergeArea.Rows.Count
    
    For lRow = lStartRow To lEndRow
        bBorder = HasHorizontalBorder(RangeToUse.Rows(lRow))
        
        ' First and last horizontal lines account for one strut,
        ' the others account for two struts each:
        If bBorder Then
            GetMultiRowStruts = GetMultiRowStruts + 1
            If (lRow > lStartRow) And (lRow < lEndRow) Then
                GetMultiRowStruts = GetMultiRowStruts + 1
            End If
        End If
    Next
End Function

#If VBA7 Then
' under Excel 2010+, RangeOrDisplayFormat() returns a DisplayFormat,
' so we can see conditional formatting
Private Function RangeOrDisplayFormat(cell As Range) As DisplayFormat
    Set RangeOrDisplayFormat = cell.DisplayFormat
End Function
#ElseIf Mac Then
' VBA7 isn't supported in Excel 2011 and 2016 for Mac, so need to
' actually check against Application.Version on that platform
Private Function RangeOrDisplayFormat(cell As Range) As Object
    If Val(Application.Version) >= 14# Then
        Set RangeOrDisplayFormat = cell.DisplayFormat
    Else
        Set RangeOrDisplayFormat = cell
    End If
End Function
#Else
' under Excel 2007 and earlier, DisplayFormat is not supported, so
' RangeOrDisplayFormat() just gives back the range it was passed
Private Function RangeOrDisplayFormat(cell As Range) As Range
    Set RangeOrDisplayFormat = cell
End Function
#End If

Private Function ZeroIfNull(v) As Long
    If Not IsNull(v) Then
        If isnumeric(v) Then
            ZeroIfNull = CLng(v)
        End If
    End If
End Function
