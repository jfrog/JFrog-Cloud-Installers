package utils

import utils.ProcessOutputStream

/**
 * Created by eliom on 6/19/18.
 */
class DSL {

    /**
     * Run shell command
     */
    static def sh = { command, outputBuffer = null, folder = null, silent = false, customEnvVariables = null, errorBuffer = null ->
        //def workdir = ConfigurationUtil.getEnvironmentVariableValue("KERMIT_WORKSPACE_DIR")
        def workdir = "/Users/danielmi/projects/soldev/.kermit-workspace"
        def commandFolder
        if (folder != null) {
            commandFolder = new File(folder, workdir)
        } else {
            commandFolder = workdir
        }

        if (!silent) {
            println "Running command at ${commandFolder}: $command"
        }
        def proc = null
        try {
            def env = System.getenv().collect { k, v -> "$k=$v" }

            if (customEnvVariables != null) {
                env.addAll( customEnvVariables.collect { k, v -> "$k=$v" })
            }

            if (command instanceof List && command.size() > 0 && command[0] instanceof List) {
                //Pipe Commands
                command.each {
                    if (proc != null) {
                        proc = proc | it.execute(env, commandFolder)
                    } else {
                        proc = it.execute(env, commandFolder)
                    }
                }
            } else {
                proc = command.execute(env, commandFolder)
            }
        } catch (IOException e) {
            println "Failed to execute command: ${e.getMessage()}"
            return -1
        }
        def processOutput = new ProcessOutputStream(silent, outputBuffer == null)
        def errorOutput = processOutput
        if (errorBuffer != null) {
            errorOutput = new ProcessOutputStream(silent, errorBuffer == null)
        }

        proc.consumeProcessOutput(processOutput, errorOutput)
        def exitStatus = proc.waitFor()
        if (!silent) {
            println "Exit: $exitStatus"
        }
        if (outputBuffer != null) {
            outputBuffer.append(processOutput.toString())
        }

        processOutput.close()

        if (errorBuffer != null) {
            errorBuffer.append(errorOutput.toString())
            errorOutput.close()
        }

        return exitStatus
    }


    //...




}
