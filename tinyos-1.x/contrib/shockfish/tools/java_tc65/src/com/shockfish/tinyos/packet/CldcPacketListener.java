package com.shockfish.tinyos.packet;

public interface CldcPacketListener {
	public void packetReceived(byte[] packet);
}
