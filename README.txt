README

The scripts have been done in Bash so for executing the scripts it requires a Linux environment or the installation of cygwin.

Once extracted to a folder the scripts can be executed directly, in the case of the aggregation scripts for methods 1 and 2 (script_aggregation_*.sh) a database like the one provided by the tutor is needed and the user and password have to be put as parameters.

The script that downloads daily the blocks of the Bitcoin chain from the previous day (script_download_block_from_yesterday.sh) has to be executed daily. For example with crontab like: 0 1 * * * {rute}/script_download_block_from_yesterday.sh

The scripts that download information from Bitcointalk (script_bitcointalk.sh), Pastebin(script_pastebin.sh) and Bitbin(script_bitbin.sh) have to be executed every two minutes for a best use. They can also be executed with crontab like: 0/2 * * * * {BASEDIR}/script_bitcointalk.sh

The rest of the scripts don't have any requisites.

It is recommended to have all the scripts in the same folder, if not some of them that work together should be modified to reflect these changes.