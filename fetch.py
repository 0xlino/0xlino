import requests
import datetime

def add_banner_to_top():
    with open('README.md', 'a') as f:
        f.truncate(0)
        f.write("<img src=\"https://github-profile-trophy.vercel.app/?username=0xlino&theme=onedark\"/>\n")
        f.write("\n")
        f.write("![](https://komarev.com/ghpvc/?username=0xlino&color=blue&style=flat)")
        f.write("\n")

def get_github_public_repos_of_user(username):            
    response = requests.get('https://api.github.com/users/' + username + '/repos?per_page=100')
    if response.status_code == 200:
        data = response.json()
        sorted_data = sorted(data, key=lambda x: x.get("pushed_at", ""), reverse=True)

        # dump nice json to file
        # with open('data.json', 'w') as f:
        #     json.dump(sorted_data, f, indent=4)

        with open('README.md', 'a') as f:
            timestampNow = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.write("### Public Repositories \n")
            for repo in sorted_data:
                # f.write("- <samp>[" + repo['name'] + "](" + repo['html_url'] + ") <kbd>" + repo['updated_at'] + "</kbd></samp>\n")
                # f.write("- [" + repo['name'] + "](" + repo['html_url'] + ")\n")
                # if repo['description'] is None: 
                # if repo['name'] == '0xlino' skip it
                if repo['name'] == '0xlino':
                    continue
                if repo['description'] is None: 
                    repo['description'] = 'No description provided'
                f.write("- [" + repo['name'] + "](" + repo['html_url'] + ") - " + repo['description'] + "\n")

            f.write("\n")
            f.write("Timestamp: " + timestampNow + "\n")
    else:
        print('Error')

add_banner_to_top()
get_github_public_repos_of_user('0xlino')
