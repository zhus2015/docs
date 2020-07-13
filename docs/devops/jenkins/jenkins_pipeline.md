# Jenkins中的pipeline语法说明

官方文档参考地址：https://www.jenkins.io/zh/doc/book/pipeline/

语法格式：

```groovy
pipeline {
  agent any
    stages {
      stage('pull') {
        steps {
          sh "git clone ${params.git_repo} ${params.app_name}/${env.BUILD_NUMBER} && cd ${params.app_name}/${env.BUILD_NUMBER} && git checkout ${params.git_ver}"
            } 
        }
    }
}
```





## env.{arge_name}  引用系统内置变量

内置变量名称说明

The following variables are available to shell scripts

- BRANCH_NAME

  For a multibranch project, this will be set to the name of the branch being built, for example in case you wish to deploy to production from `master` but not from feature branches; if corresponding to some kind of change request, the name is generally arbitrary (refer to `CHANGE_ID` and `CHANGE_TARGET`).

- CHANGE_ID

  For a multibranch project corresponding to some kind of change request, this will be set to the change ID, such as a pull request number, if supported; else unset.

- CHANGE_URL

  For a multibranch project corresponding to some kind of change request, this will be set to the change URL, if supported; else unset.

- CHANGE_TITLE

  For a multibranch project corresponding to some kind of change request, this will be set to the title of the change, if supported; else unset.

- CHANGE_AUTHOR

  For a multibranch project corresponding to some kind of change request, this will be set to the username of the author of the proposed change, if supported; else unset.

- CHANGE_AUTHOR_DISPLAY_NAME

  For a multibranch project corresponding to some kind of change request, this will be set to the human name of the author, if supported; else unset.

- CHANGE_AUTHOR_EMAIL

  For a multibranch project corresponding to some kind of change request, this will be set to the email address of the author, if supported; else unset.

- CHANGE_TARGET

  For a multibranch project corresponding to some kind of change request, this will be set to the target or base branch to which the change could be merged, if supported; else unset.

- BUILD_NUMBER

  The current build number, such as "153"

- BUILD_ID

  The current build ID, identical to BUILD_NUMBER for builds created in 1.597+, but a YYYY-MM-DD_hh-mm-ss timestamp for older builds

- BUILD_DISPLAY_NAME

  The display name of the current build, which is something like "#153" by default.

- JOB_NAME

  Name of the project of this build, such as "foo" or "foo/bar".

- JOB_BASE_NAME

  Short Name of the project of this build stripping off folder paths, such as "foo" for "bar/foo".

- BUILD_TAG

  String of "jenkins-*${JOB_NAME}*-*${BUILD_NUMBER}*". All forward slashes ("/") in the JOB_NAME are replaced with dashes ("-"). Convenient to put into a resource file, a jar file, etc for easier identification.

- EXECUTOR_NUMBER

  The unique number that identifies the current executor (among executors of the same machine) that’s carrying out this build. This is the number you see in the "build executor status", except that the number starts from 0, not 1.

- NODE_NAME

  Name of the agent if the build is on an agent, or "master" if run on master

- NODE_LABELS

  Whitespace-separated list of labels that the node is assigned.

- WORKSPACE

  The absolute path of the directory assigned to the build as a workspace.

- WORKSPACE_TMP

  A temporary directory near the workspace that will not be browsable and will not interfere with SCM checkouts. May not initially exist, so be sure to create the directory as needed (e.g., `mkdir -p` on Linux). Not defined when the regular workspace is a drive root.

- JENKINS_HOME

  The absolute path of the directory assigned on the master node for Jenkins to store data.

- JENKINS_URL

  Full URL of Jenkins, like `http://server:port/jenkins/` (note: only available if *Jenkins URL* set in system configuration)

- BUILD_URL

  Full URL of this build, like `http://server:port/jenkins/job/foo/15/` (*Jenkins URL* must be set)

- JOB_URL

  Full URL of this job, like `http://server:port/jenkins/job/foo/` (*Jenkins URL* must be set)

- GIT_COMMIT

  The commit hash being checked out.

- GIT_PREVIOUS_COMMIT

  The hash of the commit last built on this branch, if any.

- GIT_PREVIOUS_SUCCESSFUL_COMMIT

  The hash of the commit last successfully built on this branch, if any.

- GIT_BRANCH

  The remote branch name, if any.

- GIT_LOCAL_BRANCH

  The local branch name being checked out, if applicable.

- GIT_URL

  The remote URL. If there are multiple, will be `GIT_URL_1`, `GIT_URL_2`, etc.

- GIT_COMMITTER_NAME

  The configured Git committer name, if any, that will be used for FUTURE commits from the current workspace. It is read from the **Global Config user.name Value** field of the Jenkins **Configure System** page.

- GIT_AUTHOR_NAME

  The configured Git author name, if any, that will be used for FUTURE commits from the current workspace. It is read from the **Global Config user.name Value** field of the Jenkins **Configure System** page.

- GIT_COMMITTER_EMAIL

  The configured Git committer email, if any, that will be used for FUTURE commits from the current workspace. It is read from the **Global Config user.email Value** field of the Jenkins **Configure System** page.

- GIT_AUTHOR_EMAIL

  The configured Git author email, if any, that will be used for FUTURE commits from the current workspace. It is read from the **Global Config user.email Value** field of the Jenkins **Configure System** page.

- MERCURIAL_REVISION

  Full ID of revision checked out.

- MERCURIAL_REVISION_SHORT

  Abbreviated ID of revision checked out.

- MERCURIAL_REVISION_NUMBER

  Number of revision checked out (not portable across clones).

- MERCURIAL_REVISION_BRANCH

  Branch of revision checked out, if not checking out by branch head.

- MERCURIAL_REPOSITORY_URL

  URL of repository.

- SVN_REVISION

  Subversion revision number that's currently checked out to the workspace, such as "12345"

- SVN_URL

  Subversion URL that's currently checked out to the workspace.



## params.{arge_name}  引用自定义的变量