import("stdfaust.lib");

// Multiple redundant parameters for handling polyphony on the teensy
f0 = nentry("freq0", 442, 20, 2000, 0.01);
gate0 = button("gate0");
gain0 = nentry("gain0", 0.5, 0, 1, 0.01);

f1 = nentry("freq1", 442, 20, 2000, 0.01);
gate1 = button("gate1");
gain1 = nentry("gain1", 0.5, 0, 1, 0.01);

f2 = nentry("freq2", 442, 20, 2000, 0.01);
gate2 = button("gate2");
gain2 = nentry("gain2", 0.5, 0, 1, 0.01);

pedal = checkbox("sustain");

impulse(gate) = (gate - gate') > 0;

damper(gate) = select2(gate | pedal, 0.997, 1.0) : si.smoo;

hammer(hz, v, gain) = no.noise 
    : *(gain)
    : fi.lowpass(2, 200 + hz) 
    : *(en.ar(0.005, 0.04, v))
    : ma.tanh;

// String modelisation using Karplus Strong
string(f, gate, gain) = excite : (+ ~ (delayLine : filter))
with {
    excite = hammer(f, impulse(gate), gain);
    N = freq2samples(f);
    delayLine = de.fdelay(4096, N); 
    
    pivot = 400.0;
    stretch = (f / pivot) : max(1.0);
    loss = pow(0.9985, 442/f);
    w = 0.5 * (100.0 / f) : min(0.5); 
    filter(x) = (x * (1.0 - w) + x' * w) * (loss * damper(gate));
};

freq2samples(hz) = ma.SR / hz - 0.85;

soundboard(hz, input) = input <: (
      fi.resonlp(400 + hz, 1.2, 0.2)
    + fi.resonlp(900 + hz, 1.1, 0.15)
    + fi.resonlp(2200 + hz, 1.0, 0.1)
) : *(0.2);

voice0 = string(f0, gate0, gain0) * 10.0 : soundboard(f0);
voice1 = string(f1, gate1, gain1) * 10.0 : soundboard(f1);
voice2 = string(f2, gate2, gain2) * 10.0 : soundboard(f2);
process =
    (voice0
    + voice1
    + voice2
    )
    : fi.dcblocker
    * (2.0);