package utils

class ConfigurationUtil {

    static def getEnvironmentVariableValue(def name) {
        def value = System.getProperty(name)
        if (value == null) {
            value = System.getenv(name)
            if (value == null) {
                throw new Exception("Environment variable $name not set!");
            }
        }
        return value
    }




}
