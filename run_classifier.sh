#!/bin/bash -e

# NB: -e makes script to fail if internal script fails (for example when --run is enabled)

#######################################
##         CHECK ARGS
#######################################
NARGS="$#"
echo "INFO: NARGS= $NARGS"

if [ "$NARGS" -lt 1 ]; then
	echo "ERROR: Invalid number of arguments...see script usage!"
  echo ""
	echo "**************************"
  echo "***     USAGE          ***"
	echo "**************************"
 	echo "$0 [ARGS]"
	echo ""
	echo "=========================="
	echo "==    ARGUMENT LIST     =="
	echo "=========================="
	echo "*** MANDATORY ARGS ***"
	echo "--inputfile=[FILENAME] - Input file name (.json) containing images to be processed."
	
	echo ""

	echo "*** OPTIONAL ARGS ***"
	echo "=== MODEL OPTIONS ==="
	echo "--model=[MODEL] - Classifier model to be used in prediction. Options are {smorphclass,sclass-radio_3.4um-4.6um-12um-22um}. Default: smorph"
	echo ""
	
	echo "=== PRE-PROCESSING OPTIONS ==="
	echo "--imgsize=[IMGSIZE] - Size in pixels used for image resize"
	echo "--normalize_minmax - Apply minmax normalization to images "
	echo "--norm_min=[NORM_MIN] - Normalization min value (default=0)"
	echo "--norm_max=[NORM_MAX] - Normalization max value (default=1)"
	echo "--scale_to_abs_max - Scale each image channel by absolute maximum value across all channels "
	echo "--scale_to_max - Scale each image channel by its maximum value"
	echo "--zscale_stretch - Apply zscale transform to each image channel"
	echo "--zscale_contrasts=[CONTRASTS] - zscale transform contrast parameters (separated by commas) (default=0.25)"
	echo "--clip_data - Apply sigma clipping to each image channel"
	echo "--sigma_clip_low=[SIGMA_CLIP_LOW] - Min sigma clipping value (default=5)"
	echo "--sigma_clip_up=[SIGMA_CLIP_UP] - Max sigma clipping value (default=30)"
	echo "--clip_chid=[SIGMA_CHID] - Channel used to apply clipping (-1=all channels) (default=-1)"
	echo "--standardize - Apply standardization to images"
	echo "--img_means=[IMG_MEANS] - Image channel means (default=0)"
	echo "--img_sigmas=[IMG_SIGMAS] - Image channel sigmas (default=1)"
			
	echo ""
	
	echo "=== RUN OPTIONS ==="
	echo "--run - Run the generated run script on the local shell. If disabled only run script will be generated for later run."	
	echo "--scriptdir=[SCRIPT_DIR] - Job directory where to find scripts (default=/usr/bin)"
	echo "--modeldir=[MODEL_DIR] - Job directory where to find model & weight files (default=/opt/models)"
	echo "--jobdir=[JOB_DIR] - Job directory where to run (default=pwd)"
	echo "--outdir=[OUTPUT_DIR] - Output directory where to put run output file (default=pwd)"
	echo "--waitcopy - Wait a bit after copying output files to output dir (default=no)"
	echo "--copywaittime=[COPY_WAIT_TIME] - Time to wait after copying output files (default=30)"
	echo "--no-logredir - Do not redirect logs to output file in script "	
	
	echo "=========================="
  exit 1
fi


#######################################
##         PARSE ARGS
#######################################
JOB_DIR=""
JOB_OUTDIR=""
SCRIPT_DIR="/usr/bin"
MODEL_DIR="/opt/models"

DATALIST=""
DATALIST_GIVEN=false

RUN_SCRIPT=false
WAIT_COPY=false
COPY_WAIT_TIME=30
REDIRECT_LOGS=true

MODEL="smorphclass"

IMGSIZE=64
NORMALIZE_MINMAX=""
NORM_MIN=0
NORM_MAX=1
SCALE_TO_ABS_MAX=""
SCALE_TO_MAX=""
ZSCALE_STRETCH=""
ZSCALE_CONTRASTS="0.25"
CLIP_DATA=""
SIGMA_CLIP_LOW=5
SIGMA_CLIP_UP=30
CLIP_CHID=-1
STANDARDIZE=""
IMG_MEANS="0"
IMG_SIGMAS="1"

for item in "$@"
do
	case $item in 
		## MANDATORY ##	
    --inputfile=*)
    	DATALIST=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`		
			if [ "$DATALIST" != "" ]; then
				DATALIST_GIVEN=true
			fi
    ;;
    
    ## OPTIONAL ##
    --run*)
    	RUN_SCRIPT=true
    ;;
    --scriptdir=*)
    	SCRIPT_DIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --modeldir=*)
    	MODEL_DIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --outdir=*)
    	JOB_OUTDIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--waitcopy*)
    	WAIT_COPY=true
    ;;
		--copywaittime=*)
    	COPY_WAIT_TIME=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --jobdir=*)
    	JOB_DIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --no-logredir*)
			REDIRECT_LOGS=false
		;;
    
    
    --model=*)
    	MODEL=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --imgsize=*)
    	IMGSIZE=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --normalize_minmax*)
    	NORMALIZE_MINMAX="--normalize_minmax"
    ;;
    --norm_min=*)
    	NORM_MIN=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --norm_max=*)
    	NORM_MAX=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --scale_to_abs_max*)
    	SCALE_TO_ABS_MAX="--scale_to_abs_max"
    ;;
		--scale_to_max*)
    	SCALE_TO_MAX="--scale_to_max"
    ;;	
		--zscale_stretch*)
    	ZSCALE_STRETCH="--zscale_stretch"
    ;;
		--zscale_contrasts*)
    	ZSCALE_CONTRASTS=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--clip_data*)
    	CLIP_DATA="--clip_data"
    ;;
		--sigma_clip_low*)
    	SIGMA_CLIP_LOW=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;	
    --sigma_clip_up*)
    	SIGMA_CLIP_UP=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--clip_chid*)
    	CLIP_CHID=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--standardize*)
    	STANDARDIZE="--standardize"
    ;;
		--img_means*)
    	IMG_MEANS=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--img_sigmas*)
    	IMG_SIGMAS=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;	
		
    
    *)
    # Unknown option
    echo "ERROR: Unknown option ($item)...exit!"
    exit 1
    ;;
	esac
done


## Check arguments parsed
if [ "$DATALIST_GIVEN" = false ]; then
  echo "ERROR: Missing or empty DATALIST args (hint: you must specify it)!"
  exit 1
fi

if [ "$JOB_DIR" = "" ]; then
  echo "WARN: Empty JOB_DIR given, setting it to pwd ($PWD) ..."
	JOB_DIR="$PWD"
fi

if [ "$JOB_OUTDIR" = "" ]; then
  echo "WARN: Empty JOB_OUTDIR given, setting it to pwd ($PWD) ..."
	JOB_OUTDIR="$PWD"
fi



#######################################
##   SET CLASSIFIER OPTIONS
#######################################
PREPROC_OPTS="--resize_size=$IMGSIZE --upscale $NORMALIZE_MINMAX --norm_min=$NORM_MIN --norm_max=$NORM_MAX $SCALE_TO_ABS_MAX $SCALE_TO_MAX $ZSCALE_STRETCH --zscale_contrasts=$ZSCALE_CONTRASTS $CLIP_DATA --sigma_clip_low=$SIGMA_CLIP_LOW --sigma_clip_up=$SIGMA_CLIP_UP --clip_chid=$CLIP_CHID $STANDARDIZE --img_means=$IMG_MEANS --img_sigmas=$IMG_SIGMAS "

if [ "$MODEL" = "smorphclass" ]; then
	CLASSID_REMAP='{0:-1,1:0,2:1,3:2,4:3,5:4,6:5}'
	TARGET_LABEL_MAP='{0:"1C-1P",1:"1C-2P",2:"1C-3P",3:"2C-2P",4:"2C-3P",5:"3C-3P"}'
	CLASSID_LABEL_MAP='{1:"1C-1P",2:"1C-2P",3:"1C-3P",4:"2C-2P",5:"2C-3P",6:"3C-3P"}'
	TARGET_NAMES="1C-1P,1C-2P,1C-3P,2C-2P,2C-3P,3C-3P"
	NCLASSES=6
	
	MODELFILE="$MODEL_DIR/cnn-smorphclass_rgz.h5"
	WEIGHTFILE="$MODEL_DIR/weights-smorphclass_rgz.h5"

elif [ "$MODEL" = "sclass-radio_3.4um-4.6um-12um-22um" ]; then
	CLASSID_REMAP='{0:-1,1:4,2:5,3:0,6:1,23:2,24:3,6000:6}'
	TARGET_LABEL_MAP='{-1:"UNKNOWN",0:"PN",1:"HII",2:"PULSAR",3:"YSO",4:"STAR",5:"GALAXY",6:"QSO"}'
	CLASSID_LABEL_MAP='{0:"UNKNOWN",1:"STAR",2:"GALAXY",3:"PN",6:"HII",23:"PULSAR",24:"YSO",6000:"QSO"}'
	TARGET_NAMES="PN","HII","PULSAR","YSO","STAR","GALAXY","QSO"
	NCLASSES=7
	
	MODELFILE="$MODEL_DIR/cnn-sclass_radio-3.4um-4.6um-12um-22um.h5"
	WEIGHTFILE="$MODEL_DIR/weights-sclass_radio-3.4um-4.6um-12um-22um.h5"
	
else 
	echo "ERROR: Unknown/not supported MODEL argument $MODEL given!"
  exit 1
fi

CLASS_OPTS="--classid_remap=$CLASSID_REMAP --target_label_map=$TARGET_LABEL_MAP --classid_label_map=$CLASSID_LABEL_MAP --target_names=$TARGET_NAMES --nclasses=$NCLASSES --objids_excluded_in_train=-1,0 "


#######################################
##   DEFINE GENERATE EXE SCRIPT FCN
#######################################
# - Set shfile
shfile="run_predict.sh"

generate_exec_script(){

	local shfile=$1
	
	
	echo "INFO: Creating sh file $shfile ..."
	( 
			echo "#!/bin/bash -e"
			
      echo " "
      echo " "

      echo 'echo "*************************************************"'
      echo 'echo "****         PREPARE JOB                     ****"'
      echo 'echo "*************************************************"'

      echo " "
       
      echo "echo \"INFO: Entering job dir $JOB_DIR ...\""
      echo "cd $JOB_DIR"

			echo " "

      echo 'echo "*************************************************"'
      echo 'echo "****         RUN CLASSIFIER                  ****"'
      echo 'echo "*************************************************"'
				
			EXE="python $SCRIPT_DIR/run_classifier_nn.py" 
			ARGS="--predict --datalist=$DATALIST $PREPROC_OPTS --modelfile=$MODELFILE --weightfile=$WEIGHTFILE --objids_excluded_in_train=-1,0 --classid_remap=""'""$CLASSID_REMAP""'"" --target_label_map=""'""$TARGET_LABEL_MAP""'"" --classid_label_map=""'""$CLASSID_LABEL_MAP""'"" --target_names=""'""$TARGET_NAMES""'"" --nclasses=$NCLASSES"
			CMD="$EXE $ARGS"

			echo "date"
			echo ""
		
			echo "echo \"INFO: Running classifier ...\""
			
			if [ $REDIRECT_LOGS = true ]; then			
      	echo "$CMD >> $logfile 2>&1"
			else
				echo "$CMD"
      fi
      
			echo " "

			echo 'JOB_STATUS=$?'
			echo 'echo "Classifier terminated with status=$JOB_STATUS"'

			echo "date"

			echo " "

      echo 'echo "*************************************************"'
      echo 'echo "****         COPY DATA TO OUTDIR             ****"'
      echo 'echo "*************************************************"'
      echo 'echo ""'
			
			if [ "$JOB_DIR" != "$JOB_OUTDIR" ]; then
				echo "echo \"INFO: Copying job outputs in $JOB_OUTDIR ...\""
				echo "ls -ltr $JOB_DIR"
				echo " "

				echo "# - Copy output data"
				echo 'tab_count=`ls -1 *.dat 2>/dev/null | wc -l`'
				echo 'if [ $tab_count != 0 ] ; then'
				echo "  echo \"INFO: Copying output table file(s) to $JOB_OUTDIR ...\""
				echo "  cp *.dat $JOB_OUTDIR"
				echo "fi"

				echo " "
		
				echo "# - Show output directory"
				echo "echo \"INFO: Show files in $JOB_OUTDIR ...\""
				echo "ls -ltr $JOB_OUTDIR"

				echo " "

				echo "# - Wait a bit after copying data"
				echo "#   NB: Needed if using rclone inside a container, otherwise nothing is copied"
				if [ $WAIT_COPY = true ]; then
           echo "sleep $COPY_WAIT_TIME"
        fi
	
			fi

      echo " "
      echo " "
      
      echo 'echo "*** END RUN ***"'

			echo 'exit $JOB_STATUS'

 	) > $shfile

	chmod +x $shfile
}
## close function generate_exec_script()

###############################
##    RUN CLASSIFIER
###############################
# - Check if job directory exists
if [ ! -d "$JOB_DIR" ] ; then 
  echo "INFO: Job dir $JOB_DIR not existing, creating it now ..."
	mkdir -p "$JOB_DIR" 
fi

# - Moving to job directory
echo "INFO: Moving to job directory $JOB_DIR ..."
cd $JOB_DIR

# - Generate run script
echo "INFO: Creating run script file $shfile ..."
generate_exec_script "$shfile"

# - Launch run script
if [ "$RUN_SCRIPT" = true ] ; then
	echo "INFO: Running script $shfile to local shell system ..."
	$JOB_DIR/$shfile
fi


echo "*** END SUBMISSION ***"

