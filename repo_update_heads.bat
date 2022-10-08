git pull
cd gpk
git checkout master
git pull
cd ..
cd zlib
git checkout master
git pull
cd ..
cd gpk_games
git checkout master
git pull
cd ..
git add .
git commit -m "Updated submodule heads"
git push
