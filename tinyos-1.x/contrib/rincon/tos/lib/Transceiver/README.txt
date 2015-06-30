When compiling an application that uses the Transceiver, add the following line to your
Makefile:

CFLAGS += -I%T/lib/Transceiver -I%T/lib/State

Assuming your Transceiver and State components are located in /tos/lib



Transceiver was designed and created to meet several needs:

  * Transceiver combines the functionality of GenericComm, UARTComm, 
    AMStandard, and QueuedSend into one clean, compact component.
 
  * Large TinyOS program architectures require lots of components to
    be compiled together to create a system.  Some components on one mote
    may interact with the same component on a neighbor mote. Each component
    that communicates requires a TOS_Msg to build and store data. If there
    are many components and many different types of messages to be sent,
    the system can quickly use up a lot of RAM because each TOS_Msg is 
    statically allocated for each component.
    
    Transceiver allows large applications to cut down on RAM usage by making
    each component of the system share from a small pool of TOS_Msg's

  * Previous communciation implementations did not ensure a message would be
    sent if another part of the application had just sent a message as well.
    Transceiver implements a circular buffer that ensures when a message enters
    the queue to be sent, it will be sent when the proper communication channel
    becomes available. Watch out though - once you allocate a message for
    sending, you need to send it or the circular buffer will get stopped up
    waiting to send that message.

  * Radio messages are not guaranteed to get through.  Rather than 
    reconstructing a message from scratch or creating a backup in a local 
    buffer for each component that requires successful transmissions, 
    Transceiver will allow the last message from a given AM type to be resent.
    On the component end, your app will need to recognize that an 
    acknowledgement has not been received (when applicable), and resend
    the message.  The Transceiver, upon receiving a resend request, will
    traverse through its circular TOS_Msg buffer in reverse looking for
    the last message sent from the AM type that is requesting a resend. If
    it finds a message that matches the AM type, it queues it up for sending
    again.  Keep in mind that after some amount of time, the last message
    from a certain AM type may have been moved out of the buffer of sent
    messages.

  * Transceiver allows an application to accurately recognize if a message
    was received over the UART or the Radio, and send messages over the UART
    or Radio.  This makes it easy for you, the developer, to write a 
    component that doesn't care which communication channel the message
    arrived through.  

    For example, when receiving a message over radio or UART, set some variable
    inside your component that tells which communication channel the message
    was received through. Then, call a general message receiving function and 
    pass in the received message pointer. When your component gets done doing
    what it needs to do and should reply back to wherever the message came
    from, call a send() function which checks the state of the variable you
    set and send your allocated message over radio or uart. 

    You could have the mote running your app plugged directly into the computer,
    or you could have a BaseStation plugged into the computer and the mote
    sitting nearby.  Your computer's interface doesn't change, and the mote's
    functionality/interface doesn't change just because the mote is not
    plugged directly into UART.  But, radio errors aside, you can interact
    with the mote the same way in both cases and your app won't know the
    difference.  Pretty cool. 
   
  * The TinyOS 2.0 Packet interface can be optinally used to get
    the correct payload, length, etc.



Transceiver Comm Layer Footprints with 4 TOS_Msg's in the buffer, on TinyOS 1.1.15:

  Telos - 
    10,852 bytes ROM
    489 bytes RAM
    
  MicaZ -
    9,928 bytes ROM
    517 bytes RAM
    
  Mica2 -
    11,208 bytes ROM
    566 bytes RAM
    
  Mica2Dot -
    11,014 bytes ROM
    566 bytes RAM
    
    
David Moss
dmm@rincon.com 
