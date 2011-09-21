class MappingDMXOutput implements IMappingOutput
{
  
  public int startChannel, minOut, maxOut;
  
  public MappingDMXOutput(int _startChannel, int _minOut, int _maxOut)
  {
    startChannel = _startChannel;
    minOut = _minOut;
    maxOut = _maxOut;
  }
  
  public void send(float[] values)
  {
    //print("dmx not implemented yet");
    int len = values.length;
    for(int i=0;i<len;i++)
    {
      int targetValue = (int)map(values[i],0,1,minOut, maxOut);
      dmxOutput.set(startChannel+i,targetValue);
    }
  }
  
}
