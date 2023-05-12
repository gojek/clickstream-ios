import os, sys
import fileinput

project_name = 'Clickstream'
podspec_file_name = 'Clickstream.podspec'

new_tag = ""
lib_command = ""
git_add = ""
git_commit = ""
git_push = ""
pod_push_command = ""
spec_file_path = "./" + podspec_file_name
find_version_flag = False


def podCommandEdit():
    global lib_command
    global pod_push_command
    global git_add
    global git_commit
    global git_push
    lib_command = 'pod lib lint'
    pod_push_command = 'pod trunk push ' + podspec_file_name + ' --allow-warnings'
    git_add = 'git add .'
    git_commit = 'git commit -m "Updating Clickstream.podspec version"'
    git_push = 'git push origin main'


def updateVersion():
    os.system('git fetch origin main')
    os.system('git push -f origin main')

    print("--------- part 1 -------- ")
    f = open(spec_file_path, 'r+')
    infos = f.readlines()
    f.seek(0, 0)
    file_data = ""
    new_line = ""
    global find_version_flag
    print("--------- part 2 -------- ")
    for line in infos:
        if line.find(".version") != -1:
            if find_version_flag == False:
                # find s.version = "xxxx"

                spArr = line.split('.')
                last = spArr[-1]
                last = last.replace('"', '')
                last = last.replace("'", "")
                newNum = int(last) + 1

                arr2 = line.split('"')
                arr3 = line.split("'")

                versionStr = ""
                if len(arr2) > 2:
                    versionStr = arr2[1]

                if len(arr3) > 2:
                    versionStr = arr3[1]
                numArr = versionStr.split(".")

                numArr[-1] = str(newNum)
                # rejoint string
                global new_tag
                for index,subNumStr in enumerate(numArr):
                    new_tag += subNumStr
                    if index < len(numArr)-1:
                        new_tag += "."

                # complete new_tag

                if len(arr2) > 2:
                    line = arr2[0] + '"' + new_tag + '"' + '\n'

                if len(arr3) > 2:
                    line = arr3[0] + "'" + new_tag + "'" + "\n"

                # complete new_line

                print("this is new tag  " + new_tag)
                find_version_flag = True

        file_data += line

    print("--------- part 3 -------- ")
    with open(spec_file_path, 'w', ) as f1:
        f1.write(file_data)

    f.close()

    print("--------- auto update version -------- ")


def libLint():
    print("-------- waiting for pod lib lint checking ...... ---------")
    os.system(lib_command)


def pushPodspec():
	print("-------- waiting for pushing podspec file ...... ---------")
	os.system(git_add)
	os.system(git_commit)
	os.system(git_push)


def gitOperation():
    os.system('git add .')
    commit_desc = "version_" + new_tag
    commit_command = 'git commit -m "' + commit_desc + '"'
    os.system(commit_command)
    # git push
    r = os.popen('git symbolic-ref --short -q HEAD')
    current_branch = r.read()
    r.close()
    push_command = 'git push origin ' + current_branch
    
    # tag
    tag_command = 'git tag -m "' + new_tag + '" ' + new_tag
    os.system(tag_command)
    
    # push tags
    os.system('git push --tags')

def podPush():
    print("--------  waiting for pod push  ...... ---------")
    os.system(pod_push_command)



# run commands


updateVersion()
podCommandEdit()
pushPodspec()
libLint()
gitOperation()
podPush()


