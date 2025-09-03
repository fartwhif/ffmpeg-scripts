@echo off
setlocal EnableDelayedExpansion

:: Check if FFmpeg is installed
where ffmpeg >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo FFmpeg not found. Please install FFmpeg and add it to your system PATH.
    pause
    exit /b 1
)

:: Set input folder (current directory by default, or specify path)
set "INPUT_FOLDER=%~1"
if "%INPUT_FOLDER%"=="" set "INPUT_FOLDER=%CD%"

:: Ensure input folder path is absolute
pushd "%INPUT_FOLDER%" || (
    echo Input folder "%INPUT_FOLDER%" is invalid or inaccessible.
    pause
    exit /b 1
)
set "INPUT_FOLDER=%CD%"
popd

:: Set output file name
set "OUTPUT_FILE=output.mp4"

:: Set frame rate (frames per second)
set "FRAMERATE=16"

:: Calculate duration per frame (1/FRAMERATE seconds)
set /a "INVERSE_FRAMERATE=1000000/%FRAMERATE%"
set "FRAME_DURATION=0.%INVERSE_FRAMERATE%"

:: Check if input folder exists
if not exist "%INPUT_FOLDER%" (
    echo Input folder "%INPUT_FOLDER%" does not exist.
    pause
    exit /b 1
)

:: Check if folder contains PNG files
dir "%INPUT_FOLDER%\*.png" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo No PNG files found in "%INPUT_FOLDER%".
    echo Folder contents:
    dir "%INPUT_FOLDER%"
    pause
    exit /b 1
)

:: Create a temporary file list for FFmpeg
set "FILE_LIST=%TEMP%\png_list.txt"
del "%FILE_LIST%" 2>nul

:: Generate file list of PNGs with absolute paths and duration
echo Generating file list...
for %%F in ("%INPUT_FOLDER%\*.png") do (
    echo file '%%~fF' >> "%FILE_LIST%"
    echo duration %FRAME_DURATION% >> "%FILE_LIST%"
)

:: Check if file list was created
if not exist "%FILE_LIST%" (
    echo Failed to create file list "%FILE_LIST%".
    pause
    exit /b 1
)

:: Check if file list is empty
for %%A in ("%FILE_LIST%") do set "FILE_SIZE=%%~zA"
if %FILE_SIZE%==0 (
    echo No valid PNG files found in file list.
    del "%FILE_LIST%"
    pause
    exit /b 1
)

:: Display file list contents for debugging
echo Contents of %FILE_LIST%:
type "%FILE_LIST%"
echo.

:: Run FFmpeg command using file list
echo Converting PNG files to MP4...
echo FFmpeg command: ffmpeg -r %FRAMERATE% -f concat -safe 0 -i "%FILE_LIST%" -c:v libx264 -pix_fmt yuv420p -r %FRAMERATE% "%OUTPUT_FILE%"
ffmpeg -r %FRAMERATE% -f concat -safe 0 -i "%FILE_LIST%" -c:v libx264 -pix_fmt yuv420p -r %FRAMERATE% "%OUTPUT_FILE%"

:: Check if conversion was successful
if %ERRORLEVEL% equ 0 (
    echo Conversion complete. Output saved as %OUTPUT_FILE%
    :: Verify output frame rate
    echo Checking output frame rate...
    ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "%OUTPUT_FILE%"
) else (
    echo An error occurred during conversion. Check FFmpeg output above for details.
)

:: Clean up file list
del "%FILE_LIST%" 2>nul

pause