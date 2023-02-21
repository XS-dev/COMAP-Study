import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def get_name():
    temp_dataset = pd.read_csv("Fungi_temperature_curves.csv")
    temp_data = temp_dataset.values
    fungi_name = np.unique(temp_data[:, 0])
    return fungi_name


def get_temp(name_list, temp, temp_dataset):
    a = []
    for i in range(len(name_list)):
        slice = temp_dataset[(temp_dataset['species'] == name_list[i]) &
                             (temp_dataset['type'] == 'smoothed')]
        slice1 = slice[slice['temp_c'] == float(temp)]
        a.append(slice1['hyphal_rate'].values[0])
    return np.array(a)


def get_moi(name_list, moi, moi_dataset):
    a = []
    for i in range(len(name_list)):
        slice = moi_dataset[(moi_dataset['species'] == name_list[i]) &
                            (moi_dataset['type'] == 'smoothed')]
        a.append(slice[slice['matric_pot'] == float(moi)]['hyphal_rate'].values[0])
    return np.array(a)

def get_moi_max(name_list, moi_dataset):
    a = []
    for i in range(len(name_list)):
        slice = moi_dataset[(moi_dataset['species'] == name_list[i]) &
                            (moi_dataset['type'] == 'smoothed')]
        a.append(np.max(np.array(slice['hyphal_rate'])))
    return np.array(a)


def get_temp_max(name_list, temp_dataset):
    a = []
    for i in range(len(name_list)):
        slice = temp_dataset[(temp_dataset['species'] == name_list[i]) &
                            (temp_dataset['type'] == 'smoothed')]
        a.append(np.max(np.array(slice['hyphal_rate'])))
    return np.array(a)


def get_hyphal_rate(name_list, moi, temp):
    temp_dataset = pd.read_csv("Fungi_temperature_curves.csv")
    moi_dataset = pd.read_csv("Fungi_moisture_curves.csv")
    temp_max = get_temp_max(name_list, temp_dataset)
    moi_max = get_moi_max(name_list, moi_dataset)
    moi_hyphal_rate = get_moi(name_list, moi, moi_dataset)
    temp_hyphal_rate = get_temp(name_list, temp, temp_dataset)

    max_rate = np.array([max(temp_max[i], moi_max[i]) for i in range(len(temp_max))])
    a = moi_hyphal_rate / moi_max
    b = temp_hyphal_rate / temp_max
    hyphal_rate = max_rate * a * b
    return hyphal_rate, a

fungi_names = ['p.flav.s', 'p.har.n', 'm.trem.n', 'p.sang.s', 'h.seti.n']
x = np.linspace(0, -5, 501)
for name in fungi_names:
    moi_dataset = pd.read_csv("Fungi_moisture_curves.csv")
    moi_data = moi_dataset.values
    slice = moi_dataset[(moi_dataset['species'] == name) &
                    (moi_dataset['type'] == 'smoothed')]
    y = slice["hyphal_rate"].values
    plt.plot(x, y, label=name)
    plt.yticks(np.linspace(0, 10, 6), fontsize=12)
    plt.xticks(np.linspace(-5, 0, 6), fontsize=12)
    plt.ylabel("Hyphal extension rate(mm/day)", fontsize=14)
    plt.xlabel("Water potential(MPa)", fontsize=14)
    plt.grid(color='grey', linestyle='--', linewidth=1, alpha=0.3)
plt.legend()
plt.show()

x = np.linspace(-5, 50, 5501)
for name in fungi_names:
    moi_dataset = pd.read_csv("Fungi_temperature_curves.csv")
    moi_data = moi_dataset.values
    slice = moi_dataset[(moi_dataset['species'] == name) &
                    (moi_dataset['type'] == 'smoothed')]
    y = slice["hyphal_rate"].values
    plt.plot(x, y, label=name)
    plt.yticks(np.linspace(0, 15, 6), fontsize=12)
    plt.xticks(np.linspace(0, 50, 6), fontsize=12)
    plt.ylabel("Hyphal extension rate(mm/day)", fontsize=14)
    plt.xlabel("Temperature()", fontsize=14)
    plt.grid(color='grey', linestyle='--', linewidth=1, alpha=0.3)
plt.legend()
plt.show()
