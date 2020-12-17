# -*- coding: utf-8 -*-
import os
import psutil
from multiprocessing import cpu_count
load_15 = int(os.getloadavg()[2]*100)
if load_15 > 300*cpu_count():
    os.system('/sbin/reboot')
mem = psutil.virtual_memory().percent
if mem > 90:
    os.system('/sbin/reboot')
