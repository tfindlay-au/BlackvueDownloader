# Blackvue Downloader

### Purpose
This script download camera footage from my vehicle to provide a longer term backup.
This script is based on the good work done by other Blackvue camera owners leveraging the API available on the camera device itself, without them this code would not exist.
I have adapted community snippets and samples for my own purpose, this will not work for everyone, and I encourage you to modify and adapt it for your own purpose. 

This code is provided without warranty, use at your own risk.

### Requirements
1. This setup requires the camera has a fixed IP address, I do this via my router (DHCP server).
2. The camera is configured with my wireless network SSID + WEP key but is not configured with a cloud account as I do not need my camera footage to be uploaded to the internet.
3. This setup requires the camera is powered. I use a power magic pro but you may use the battery pack or other mechanism

### Configuring
This script requires the following items to be set within the script:
- *DASHCAM_IP1*: Sets the IP address expected for the camera
- *FILE_LOCATION*: Sets where the video files will be placed
- *PIDFILE*: Sets a location of a semaphore file to track program running
- *MAX_SIZE*: Sets the amount of disk space you want to use for camera footage

### Usage
Personally, I execute this via crontab like so:
```
0 * * * * /home/user/BlackvueDownloader.sh 2>&1 >> /home/user/BlackvueDownloader.log
```

This runs each hour and produces a log file of what was done. If the camera was not available on the network, it will simply report:
`Dashcam not found on <ip address>`

If the camera was connected to the network, it will log output like:
```
Dashcam found on 10.1.10.110
.. downloading /Record/19700101_000000_NF.mp4
```

Where the file names (as far as I can tell) are:
- YYYY = 4 digit year
- MM = 2 digit month
- DD = 2 digit day
- _ = separator
- HH = 2 digit hour in 24hr format (00-23)
- MM = 2 digit minute
- SS = 2 digit second
- _ = separator
- N = Unknown
- F/R = Single alpha to indicate Front or Rear camera

The file extensions include:
- gps = Plain text, unknown format containing longitude + latitude data if available
- 3gf = Unknown
- thm = Unknown
- mp4 = H265 encoded video with AAC audio in an MPEG container

