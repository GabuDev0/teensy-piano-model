import("stdfaust.lib");

freq = nentry("freq", 442, 20, 2000, 0.01);
gate = button("gate");
gain = nentry("gain", 0.5, 0, 1, 0.01);
pedal = checkbox("sustain");

// 1. Hammer Trigger
impulse = (gate - gate') > 0;

// 2. The Damper (Slowed down the release)
// 0.97 means the sound lingers slightly even after you let go.
damper = select2(gate | pedal, 0.997, 1.0) : si.smoo;

hammer(freq, v) = no.noise 
    : *(gain)
    : fi.lowpass(2, 200 + freq) 
    : *(en.ar(0.02, 0.04, v))
    : ma.tanh;
        
string(N) = excite : (+ ~ (delayLine : filter))
with {
    excite = hammer(freq, impulse);
    delayLine = de.fdelay(4096, N); 
    
    loss = 0.9985; 
    filter(x) = (x + x') * 0.5 * (loss * damper);
};

freq2samples(hz) = ma.SR / hz - 0.85;

soundboard(input) = input <: (
      fi.resonlp(400, 1.2, 0.2)
    + fi.resonlp(900, 1.1, 0.15)
    + fi.resonlp(2200, 1.0, 0.1)
) : *(0.2);

process = string(freq2samples(freq))*10.0 : soundboard <: _,_;