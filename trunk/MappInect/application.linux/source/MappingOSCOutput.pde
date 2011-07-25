class MappingOSCOutput implements IMappingOutput
{
  public String address;
  
  public MappingOSCOutput(String _host, int _port, String _address)
  {
    this.address = _address;
    println(" > New OSC Output : address :"+address);
  }
  
  public void send(float[] values)
  {
    //println("OSC Output not sending anything yet");
    OscMessage msg = new OscMessage(address);
    int numValues = values.length;
    for(int i=0;i<numValues;i++){
      msg.add(values[i]); /* add an int to the osc message */
    }
  
    /* send the message */
    oscP5.send(msg, oscRemoteHost); 
  }
  
}
