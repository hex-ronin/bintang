# Bintang Drop-in Court Summary

This repo contains code that extracts how many courts can be reserved in Bintang.  It is intended to be low overhead to Bintang's servers but provides a quick way for Bintang members to figure out whether a certain location has a sufficient number of free courts for them to drop-in. 

The main code is in `find-free.sh`.  It takes three parameters.  
  1. The directory where the configuration files are.  These configuration files give specific information about each Bintang location that the script uses.
  1. The directory that holds any temporary files generated by the script.  The script leaves temporary files after each execution in case they are needed to be debugged.  They are cleaned up at the beginning of the run of the script if the same temporary directory is given.
  1. The directory where the `summary.html` is written to.  This is the directory where your webserver should be pointing at.

For example,
`
# The following gives  the conf directory as first parameter and the current directory as both the temporary and final location.
$ ./find-free.sh ./conf . .

# The following uses Linux tmp as the temporary location
$ ./find-free.sh ./conf /tmp .
`

You can run this as a cron job.  

`
# This runs it every hour from 8-3pm.  Make sure to change the directories.
0 8-15 * * * ./find-free.sh ./conf /tmp /public-html
`

This repo also contains a `bintang.yml` which deploys a web server in kubernetes that can be used to serve up the web page generated.
