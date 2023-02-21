import numpy as np
import matplotlib.pyplot as plt
from math import exp
import pandas as pd
import Get_hyphal_rate
# import dataprocess

fungi_names = ['p.flav.s', 'p.har.n', 'm.trem.n', 'p.sang.s', 'h.seti.n']


def lineartransform(x):  # turn moisture to water potential
    y = -5 + x / 20
    return format(y, '.2f')


def f(hyphal_rate, temperature, factor):  # get decomposition rate by interpolation

    delta = (2.633 - 1.519) / 120
    a = int((temperature - 10) / 0.1) * delta + 1.519
    y = exp(a) * (hyphal_rate ** (0.44)) * factor / 100 / 122
    return y


def get_m(humidity, temperature, fungi_names):  # get the growth-hyphal extension ratio
    water_potential = lineartransform(humidity)
    m, factor = Get_hyphal_rate.get_hyphal_rate(fungi_names, water_potential,
                                            temperature)
# get_hyphal_rate: get hyphal extension rate under certain moisture and temperature
    return m, factor

delta_t, s, t_step = 1, 5, 122
F, D, l = np.ones((s, t_step)), np.ones((s, t_step - 1)), np.ones((s, t_step))
V = np.zeros(t_step)
V[0], K = 1, 300
F[:, 0] = np.array([1, 25, 5, 15, 10])
n = np.array([100, 100, 100, 100, 100])
T, H = dataprocess.get_longTH(0)
for i in range(t_step - 1):
    humidity = H[i]
temperature = T[i]
print(i)
m, factor = get_m(humidity, temperature, fungi_names)
r = np.diag(m / 5)
c = [1 - mi / np.sum(m) for mi in m]
C = np.array([[1, c[0], c[0], c[0], c[0]],
              [c[1], 1, c[1], c[1], c[1]],
              [c[2], c[2], 1, c[2], c[2]],
              [c[3], c[3], c[3], 1, c[3]],
              [c[4], c[4], c[4], c[4], 1]])
vector = F[:, i] / n
B = np.diag(np.diag(r * F[:, i])) @ C
F[:, i + 1] = F[:, i] + (r @ F[:, i] - B @ vector) * delta_t
l[:, i + 1] = l[:, i] + delta_t * (1 - (np.sum(F[:, i])) / K) * m.T
D[:, i] = f((1 - (np.sum(F[:, i])) / K) * m.T, temperature, factor)
V[i + 1] = V[i] + (-np.sum(D[:, i])) * delta_t * V[i] * (1 - (np.sum(F[:, i])) / K)
t = [i * delta_t for i in range(t_step)]
plt.plot(t, F[0, :], c='steelblue', label='p.flav.s')
plt.plot(t, F[1, :], c='darkorange', label='p.har.n')
plt.plot(t, F[2, :], c='forestgreen', label='m.trem.n')
plt.plot(t, F[3, :], c='firebrick', label='p.sang.s')
plt.plot(t, F[4, :], c='mediumpurple', label='h.seti.n')
plt.xlabel("Time(day)", fontsize=16)
plt.ylabel("The density of fungi" + "" + "(g/m" + "\u00b2" + ")", fontsize=16)
plt.tick_params(labelsize=14)
plt.legend(fontsize=10)
plt.show()
plt.plot(t, V, c='b', alpha=0.6, linewidth=2)
plt.xlabel("Time(day)", fontsize=14)
plt.ylabel("Relative density of woody fibers", fontsize=14)
plt.tick_params(labelsize=12)
plt.show()
