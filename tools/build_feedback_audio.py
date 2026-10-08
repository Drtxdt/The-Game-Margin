"""Deterministic original foley and feedback; no external recordings."""
from pathlib import Path
import math, random, struct, wave
root=Path(__file__).resolve().parents[1]/'assets/audio'
rate=44100
for kind,duration in [('foot',.085),('collect',.65),('impact',.16),('page',.22)]:
    rng=random.Random(54)
    samples=[]
    filtered=0.
    for i in range(int(rate*duration)):
        t=i/rate
        noise=rng.uniform(-1,1)
        filtered=.82*filtered+.18*noise
        if kind=='foot':
            value=(filtered*.8+math.sin(t*2*math.pi*115)*.3)*math.exp(-t*52)
        elif kind=='collect':
            value=sum(math.sin(2*math.pi*f*t)*math.exp(-t*(5+n)) for n,f in enumerate([659.25,987.77,1318.51]))*.16
            value*=min(1,t*90)
        elif kind=='impact':
            value=(filtered*.7+math.sin(2*math.pi*(190*t-260*t*t))*.35)*math.exp(-t*27)
        else:
            value=(noise-filtered)*.2*math.sin(math.pi*t/duration)**2
        samples.append(int(max(-1,min(1,value))*16000))
    with wave.open(str(root/f'{kind}.wav'),'wb') as file:
        file.setparams((1,2,rate,0,'NONE','not compressed'))
        file.writeframes(struct.pack('<'+'h'*len(samples),*samples))
