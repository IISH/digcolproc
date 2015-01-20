class SleepService extends Thread implements Runnable {

    long time

    SleepService(long time) {
        this.time = time
    }

    void run() {
        println("Pausing for " + time / 1000 + " seconds")
        sleep(time)
    }
}

long t = ( args.length == 0 ) ? 1000 : args[0] as long
final SleepService sleepService = new SleepService(t)
sleepService.run()