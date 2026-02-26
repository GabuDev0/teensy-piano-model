import("stdfaust.lib");


brightness = hslider("brightness", 0.0, 0.0, 1.0, 0.01);

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

f3 = nentry("freq3", 442, 20, 2000, 0.01);
gate3 = button("gate3");
gain3 = nentry("gain3", 0.5, 0, 1, 0.01);

f4 = nentry("freq4", 442, 20, 2000, 0.01);
gate4 = button("gate4");
gain4 = nentry("gain4", 0.5, 0, 1, 0.01);

f5 = nentry("freq5", 442, 20, 2000, 0.01);
gate5 = button("gate5");
gain5 = nentry("gain5", 0.5, 0, 1, 0.01);

f6 = nentry("freq6", 442, 20, 2000, 0.01);
gate6 = button("gate6");
gain6 = nentry("gain6", 0.5, 0, 1, 0.01);

f7 = nentry("freq7", 442, 20, 2000, 0.01);
gate7 = button("gate7");
gain7 = nentry("gain7", 0.5, 0, 1, 0.01);

pedal = checkbox("sustain");

impulse(gate) = (gate - gate') > 0;

damper(gate) = select2(gate | pedal, 0.997, 1.0) : si.smoo;

hammer(f, trigger, gain) = no.noise
    : *(gain) *(442/f) : ma.tanh // increases the volume of the low notes, decreases the volume of the high notes
    : fi.lowpass(2, brightness*400 + f + gain*400)
    : *(en.ar(0.001, 0.04, trigger))
    : ma.tanh;


// String modelisation using Karplus Strong
string(f, gate, gain) = excite : (+ ~ (delayLine : filter))
with {
    excite = hammer(f, impulse(gate), gain);
    N = freq2samples(f);
    delayLine = de.fdelay(4096, N); 
    
    loss = 0.9985;
    w = 0.5 * (100.0 / f) : min(0.5);

    filter(x) = (x * (1.0 - w) + x' * w) * (loss * damper(gate));
};

freq2samples(hz) = ma.SR / hz - 1.0;

soundboard(hz, input) = input <: (
      fi.resonlp(400 + hz, 1.2, 0.2)
    + fi.resonlp(900 + hz, 1.1, 0.15)
    + fi.resonlp(2200 + hz, 1.0, 0.1)
);

// Manually summed voices for polyphony in teensy
voice0 = string(f0, gate0, gain0) : soundboard(f0);
voice1 = string(f1, gate1, gain1) : soundboard(f1);
voice2 = string(f2, gate2, gain2) : soundboard(f2);
voice3 = string(f3, gate3, gain3) : soundboard(f3);
voice4 = string(f4, gate4, gain4) : soundboard(f4);
voice5 = string(f5, gate5, gain5) : soundboard(f5);
voice6 = string(f6, gate6, gain6) : soundboard(f6);
voice7 = string(f7, gate7, gain7) : soundboard(f7);

process =
    (voice0
    + voice1
    + voice2
    + voice3
    + voice4
    + voice5
    + voice6
    + voice7
    )
    : fi.dcblocker
    * (2.0);