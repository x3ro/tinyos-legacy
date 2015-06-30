T-MAC Readme
------------
This Timeout-MAC (T-MAC) implementation for TinyOS is by Tom Parker <T.E.V.Parker@ewi.tudelft.nl> (TU Delft/TNO) 
and is based on the S-MAC code by Wei Ye <weiye@isi.edu> and Honghui Chen (University of California).
T-MAC was originally created by Tijs Van Dam, also of TU Delft. The original paper can be found at
http://www.consensus.tudelft.nl/documents_delft/03vandam.pdf 

T-MAC has been tested with the 1.1.10 TinyOS CVS snapshot, nesc versions >=1.1.2a, and make 3.80.
Other versions of software are unsupported and may break. In particular, the new build system *requires* 
make 3.80 or greater in order to function, and nesc <1.1.2a has been shown to cause unusual effects to T-MAC

Note that due to the delays created by the awake/sleep periods in T-MAC, it becomes increasingly likely
that a Send() call will fail, especially when sending messages in rapid succession. Therefore, Send()
calls return values should always be checked, and retried at a later point if required(after you have 
recieved a SendDone()).
 
