all: javaSend.class

PWMMessage.java:
	mig -java-classname=PWMMessage java ../include/PWMMessage.h PWMMsg -o PWMMessage.java

javaSend.class: PWMMessage.java ../lib/robot.java
	javac javaSend.java ../lib/robot.java PWMMessage.java