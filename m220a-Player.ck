// @title m220a-Player.ck
// @desc a sample sound player goes with DataReader class
// @author Chris Chafe (cc@ccrma)

//=== TODO: modify this path and name for your system ===//
"/Users/camillenoufi/cnoufi_G/y1/220a/hw1/" => string dataDir;
"acres3.dat" => string dataFile;

// update rate in ms
1000 => float update; 

// new class to manage envelopes
class Env
{
  Step s => Envelope e => blackhole; // feed constant into env
  update::ms => e.duration; // set ramp time
  fun void target (float val) { e.target(val); }
}

class Player
{
  SinOsc s => NRev rev => dac;
  rev.mix(0.05);
  Env amp, freq;
  fun void run() // sample loop to smoothly update gain
  { 
    while (true)
    {
      s.gain(amp.e.last());
      s.freq(freq.e.last());
      1::samp => now;
    }
  }  spork ~ run(); // run run
}

DataReader data_in;
data_in.setDataSource(dataDir + dataFile);
data_in.start(); 
Player p;
0 => int count;
while (!data_in.isFinished())
{
    
    // next data point, scaled in 0.0 - 1.0 range
    data_in.scaledVal() => float w; 
    p.amp.target(0.5 * Math.pow(w, 2.0));
    p.freq.target(Std.mtof(80.0 + w*20.0));

    update::ms => now;
    count++;
    <<< count >>>;
}
