# all : MotorStateMsg.class MotorQueryMsg.class MotorTrimMsg.class MotorMovementMsg.class



# MotorStateMsg.class : MotorStateMsg.java
# 	javac MotorStateMsg.java

# MotorQueryMsg.class : MotorQueryMsg.java
# 	javac MotorQueryMsg.java

# MotorTrimMsg.class : MotorTrimMsg.java
# 	javac MotorTrimMsg.java

# MotorMovementMsg.class : MotorMovementMsg.java
# 	javac MotorMovementMsg.java



# MotorStateMsg.java : ../include/Messages.h
# 	mig -target=telosb -java-classname=MotorStateMsg java ../include/Messages.h MotorState -o MotorStateMsg.java

# MotorQueryMsg.java : ../include/Messages.h
# 	mig -target=telosb -java-classname=MotorQueryMsg java ../include/Messages.h MotorQuery -o MotorQueryMsg.java

# MotorTrimMsg.java : ../include/Messages.h
# 	mig -target=telosb -java-classname=MotorTrimMsg java ../include/Messages.h MotorTrim -o MotorTrimMsg.java

# MotorMovementMsg.java : ../include/Messages.h
# 	mig -target=telosb -java-classname=MotorMovementMsg java ../include/Messages.h MotorMovement -o MotorMovementMsg.java


# clean :
# 	rm -f *.class MotorStateMsg.java MotorQueryMsg.java MotorTrimMsg.java MotorMovementMsg.java

