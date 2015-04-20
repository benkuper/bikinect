# Introduction #

This pages explains what is a mapping and how does it work.


# Details #


**What is a mapping ?**

To keep things simple, mappings are informations grabbed from the kinect, calculated (processed) in a specific way and then sent out via different protocols.
This allows non-coders to be able to access complex datas from the kinect in an easy and creative way.


**How does it work ?**


You can think of a mapping as an action chain that begins with informations grabbed from the Kinect and that ends with the output sent.


This is a basic representation of a simple mapping :

Information from Kinect ---> Some calculation --> Value mapping --> Output.


Let's work on a reel example. Imagine that I want to get the horizontal position of my right hand, and sent this on a midi channel. That would look like this :

Get right joint position from kinect ---> retrieve the X value from the joint ---> Map the position between 0 and 127 (because of midi output) ---> send the processed value to a specific midi channel.


More complex example will be added to the wiki, a PDF documentation is being written.