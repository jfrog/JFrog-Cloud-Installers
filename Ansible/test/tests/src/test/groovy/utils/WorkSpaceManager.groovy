package utils

/**
 * Created by eliom on 6/26/18.
 */
class WorkspaceManager {

    //TODO: Make it Thread safe
    def static currentPath = []

    def static pushPath(path) {
        currentPath.push(path)
    }

    def static popPath() {
        currentPath.pop()
    }

    def static getCurrentDir() {
        def workspaceRoot = ConfigurationUtil.getWorkspaceDir()
        if (currentPath.size() > 0) {
            def currentDir = new File(currentPath.join('/'), workspaceRoot)
            if (!currentDir.exists()) {
                currentDir.mkdirs()
            }
            return currentDir
        } else {
            return workspaceRoot
        }
    }

}
