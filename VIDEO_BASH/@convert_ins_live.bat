ffmpeg -i "%~1" -c:v libx264 -vf scale=720:-1 -preset veryfast -crf 18 -r 29.97 -c:a copy "%~n1_720P_30fps".mp4
pause