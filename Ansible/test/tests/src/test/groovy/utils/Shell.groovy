package utils

class Shell {

    def executeProc(cmd) {
        println(cmd)
        def proc = cmd.execute()

        proc.in.eachLine {line ->
            println line
        }

        println proc.err.text

        proc.exitValue()
    }
}
