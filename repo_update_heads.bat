@echo off

REM Array of repositories
set "gpk_games_repos=gpk zlib gpk_games gpk_data"

REM Loop through each repository
for %%i in (%gpk_games_repos%) do (
    cd %%i
    git checkout master
    git pull
    cd ..
    git add %%i
)

git commit -m "Updated submodules to latest heads."
git push