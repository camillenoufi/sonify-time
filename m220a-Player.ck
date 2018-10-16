// @title m220a-Duo.ck
// @desc a sound player with polyphony for DataReader class
// @author Camille Noufi - modified from Chris Chafe's original version (cc@ccrma)


//=== SET-UP ===//

// get name
me.arg(0) => string filename;
if( filename.length() == 0 ) "/Users/camillenoufi/cnoufi_G/y1/220a/hws/hw1/"+ "h.wav" => filename;


"/Users/camillenoufi/cnoufi_G/y1/220a/hws/hw1/" => string dataDir; // osx template
// update rate in ms
460 => float update; 

dac => WvOut2 writer => blackhole;            
writer.wavFilename(filename);
null @=> writer;

//=== CLASS DECLARATIONS ===//

// new class to manage envelopes
class Env
{
    Step s => Envelope e => blackhole; // feed constant into env
    update::ms => e.duration; // set ramp time
    fun void target (float val) { 
        e.target(val); 
    }
}

//Bow with Vibrato
class Player
{
    Bowed bow => NRev rev;
    SndBuf buf => rev;
    fun void setChan(int c) { rev => dac.chan(c); }
    rev.mix(0.1);
    Env amp, freq;
    Math.random2f( 0.0, 1.0 ) => bow.bowPressure;
    Math.random2f( 0.0, 1.0 ) => bow.bowPosition;
    Math.random2f( 0.0,1.0 ) => bow.vibratoFreq;

    fun void run() // sample loop to smoothly update gain
    {
        while (true) {
            bow.vibratoGain(amp.e.last());
            bow.gain(amp.e.last());
            bow.volume(amp.e.last());
            buf.gain(0.5*amp.e.last());
            //bow.freq(freq.e.last());
            .3 => bow.noteOn;
            1::samp => now;
        }
    }
    spork ~ run(); // run 'run' function as a new shred
}

//=== SHREDDING  ===//

// sporking multiple shreds programmatically
spork ~ go("acres3.dat", "fire.wav", 1); //right chan
spork ~ go("earthquake.dat", "earthquake.wav", 0); //left chan


// function for shredding
fun void go(string file, string effect, int chan)
{
    DataReader reader;
    reader.setDataSource(dataDir + file);   
    Player p;
    p.buf.read(dataDir + effect);
    
    //left-channel "bass"
    if(chan==0) {
        reader.start();
        p.buf.pos(0);  
    }
    //right-channel "treble"
    else if(chan==1) {
        (update*29)::ms => now;
        reader.start();
        p.buf.pos(0);   
    }
    
    
    // left-channel "bass bow"    
    if(chan==0) {
        p.setChan(chan);
        while (!reader.isFinished())            
        {                
            // next data point, scaled in 0.0 - 1.0 range               
            reader.scaledVal() => float w;                 
            p.amp.target(0.5 * w);                
            p.bow.freq(Std.mtof(40.0 + w*12.0)); 
            update::ms => now;
        }
        //integrate earthquake sndbuf
    }
    
    //right-channel "treble mandolin"
    else if(chan==1) {
        p.setChan(chan);
        while (!reader.isFinished())            
        {                
            // next data point, scaled in 0.0 - 1.0 range               
            reader.scaledVal() => float w; 
            p.amp.target(0.5* w);                                  
            p.bow.freq(Std.mtof(69.0 + w*24.0));      
            update::ms => now;
        }
    } 
}

// to make the main shred alive
100::second => now;