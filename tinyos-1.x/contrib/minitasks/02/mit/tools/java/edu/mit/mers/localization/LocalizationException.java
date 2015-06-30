package	edu.mit.mers.localization;

public class LocalizationException extends Exception {
    public String reason;
    LocalizationException(String text) {reason = text;}
}
