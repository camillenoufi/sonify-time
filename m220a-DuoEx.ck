// @title m220a-Duo.ck
// @desc a sound player with polyphony for DataReader class
// @author Chris Chafe (cc@ccrma)

//=== TODO: modify this path and name for your system ===//
// "/home/cc/220a/hw1/" => string dataDir; // linux template
"/Users/camillenoufi/cnoufi_G/y1/220a/hw1/" => string dataDir; // osx template

// update rate in ms
200 => float update; 

// new class to manage envelopes
class Env
{
    Step s => Envelope e => blackhole; // feed constant into env
    update::ms => e.duration; // set ramp time
    fun void target (float val) { e.target(val); }
}

class Player
{
    SinOsc s => NRev rev;
    fun void setChan(int c) { rev => dac.chan(c); }
    rev.mix(0.05);
    Env amp, freq;

    fun void run() // sample loop to smoothly update gain
    {
        while (true) {
            s.gain(amp.e.last());
            s.freq(freq.e.last());
            1::samp => now;
        }
    }
    spork ~ run(); // run 'run' function as a new shred
}

// sporking multiple shreds programmatically
spork ~ go("acres3.dat", 0);
spork ~ go("campito.dat", 1);

// function for shredding
fun void go(string file, int chan)
{
    DataReader reader;
    reader.setDataSource(dataDir + file);
    reader.start(); 
    Player p;
    p.setChan(chan);
    
    while (!reader.isFinished())
    {
        // next data point, scaled in 0.0 - 1.0 range
        reader.scaledVal() => float w; 
        p.amp.target(0.5 * Math.pow(w, 2.0));
        p.freq.target(Std.mtof(80.0 + w*20.0));        
        update::ms => now;
    }
}

// to make the main shred alive
1::day => now;