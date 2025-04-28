numSweepPoint = 30
freqStart = 36
freqEnd = 54

interval = (freqEnd - freqStart) / numSweepPoint

value = freqStart

for _ in range(numSweepPoint):
    value += interval

print(value)