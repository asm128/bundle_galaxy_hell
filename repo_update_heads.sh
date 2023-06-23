#!/bin/bash

# Array of repositories
repos=("gpk" "zlib" "gpk_games")

# Loop through each repository
for repo in "${repos[@]}"
do
    cd "$repo"
    git checkout master
    git pull
    cd ..
    git add "$repo"
done

git commit -m "Updated submodules to latest heads."
git push
