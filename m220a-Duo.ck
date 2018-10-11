// @title m220a-Duo.ck
// @desc a sound player with polyphony for DataReader class
// @author Camille Noufi modified from Chris Chafe's  (cc@ccrma)


//=== SET-UP ===//

"/Users/camillenoufi/cnoufi_G/y1/220a/hw1/" => string dataDir; // osx template
// update rate in ms
600 => float update; 
// scale
[0, 2, 4, 7, 8, 11] @=> int scale[];

//=== CLASS DECLARATIONS ===//

// new class to manage envelopes
class Env
{
    Step s => Envelope e => blackhole; // feed constant into env
    (update/10.0)::ms => e.duration; // set ramp time
    fun void target (float val) { 
        e.target(val); 
    }
}

//Oscillator
class Player
{
    PulseOsc s => NRev rev;
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

//Bow with Vibrato
class PlayerBow
{
    Bowed bow => NRev rev;
    fun void setChan(int c) { rev => dac.chan(c); }
    rev.mix(0.1);
    Math.random2f( 0, 1 ) => bow.bowPressure;
    Math.random2f( 0, 1 ) => bow.bowPosition;
    Math.random2f( 0, 12 ) => bow.vibratoFreq;
    Env amp, freq;
    fun void run() // sample loop to smoothly update gain
    {
        while (true) {
            bow.vibratoGain(amp.e.last());
            bow.volume(amp.e.last());
            bow.freq(freq.e.last());
            .8 => bow.noteOn;
            1::samp => now;
        }
    }
    spork ~ run(); // run 'run' function as a new shred
}

//Mandolin
class PlayerMand
{
    Mandolin m => JCRev rev;
    fun void setChan(int c) { rev => dac.chan(c); }
    rev.mix(0.1);
    rev.gain(0.5);
    m.bodySize(0.5);
    m.pluckPos(0.5);
    Env amp, freq;
    fun void run() // sample loop to smoothly update gain
    {
        while (true) {
            m.freq(freq.e.last());
            m.pluck(0.4 + amp.e.last());
            1::samp => now;
        }
    }
    spork ~ run(); // run 'run' function as a new shred
}



//=== SHREDDING  ===//

// sporking multiple shreds programmatically
spork ~ go("acres3.dat", 1); //right chan
spork ~ go("earthquake.dat", 0); //left chan


// function for shredding
fun void go(string file, int chan)
{
    DataReader reader;
    reader.setDataSource(dataDir + file);   
    //PlayerMand pbow;
    //PlayerMand pmand;
    //Player pbow;
    //Player pmand;
    PlayerBow pbow;
    PlayerBow pmand;
    
    //left-channel "bass"
    if(chan==0) {
        reader.start();
    }
    //right-channel "treble"
    else if(chan==1) {
        (update*24)::ms => now;
        reader.start(); 
    }
    
    
    // left-channel "bass bow"    
    if(chan==0) {
        pbow.setChan(chan);
        while (!reader.isFinished())            
        {                
            // next data point, scaled in 0.0 - 1.0 range               
            reader.scaledVal() => float w;                 
            pbow.amp.target(0.4 * w);                
            pbow.freq.target(Std.mtof(57.0 + w*12.0)); //    
            update::ms => now;
        }
        //integrate earthquake sndbuf
    }
    
    //right-channel "treble mandolin"
    else if(chan==1) {
        pmand.setChan(chan);
        while (!reader.isFinished())            
        {                
            // next data point, scaled in 0.0 - 1.0 range               
            reader.scaledVal() => float w;                 
            pmand.amp.target(0.5 * w);                
            pmand.freq.target(Std.mtof(69.0 + w*24.0));        
            update::ms => now;
        }
        //integrate fire-crackle sndbuf
    } 
}

// to make the main shred alive
1::day => now;