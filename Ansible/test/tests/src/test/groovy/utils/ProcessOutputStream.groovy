package utils

public class ProcessOutputStream extends ByteArrayOutputStream{

    private boolean silent = false;
    private boolean discardOutput = false;

    public ProcessOutputStream(boolean silent, boolean discardOutput) {
        this.silent = silent;
        this.discardOutput = discardOutput;
    }

    @Override
    public synchronized void write(int b) {
        if (!silent) {
            System.out.write(b);
        }
        if (!discardOutput) {
            super.write(b);
        }
    }

    @Override
    public synchronized void write(byte[] b, int off, int len) {
        if (!silent) {
            System.out.write(b, off, len);
        }
        if (!discardOutput) {
            super.write(b, off, len);
        }
    }
}