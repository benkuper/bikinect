Here is the place where simple and common problems will be answered. For more complex issues, please use the issue queue.

**==When I launch MappInect, nothing happens==**

There are several possibilities for that problem to occur. Basically, it's because the program gets an error at the runtime setup.
These errors can be caused by :

> - _A driver problem_ : Be sure to have the latest OpenNI x86 drivers installed (with Nite and SensorKinect). x64 drivers won't work for the moment as SensorKinect has not been released in 64-bit version.

> - _A config file problem_ : Be sure that the data folder is present in the application folder, and that it contains a config.xml and the loaded mapping file.

> - _A midi device problem_ : Especially on OSX, there seems to be no virtual midi device setup by default. This can cause a problem for the application when searching for available midi devices. As you'll need anyway a midi loopback device to run mappInect, i recommend you to install : http://nerds.de/en/ipmidi_osx.html or other virtual midi device.