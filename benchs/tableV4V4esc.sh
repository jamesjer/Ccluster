#!/bin/bash
# bernoulli: deg 64, eps = -53 -530 -5300
# mignotte : deg 64, bitsize = 14, eps = -53, -530, -5300
# #            deg 128, bitsize = 14, eps = -53, -530, -5300
# cluster  : deg 81, eps = -2, -4, -16

# wilkinson: deg 64, eps = -53, -530, -5300
# wilkMul  : deg 66, eps = -53, -530, -5300
# spiral   : deg 64, eps = -53, -530, -5300
#mignotteGen: deg64, eps = -53, -530, -5300
usage()
{
   echo "Usage: ./tableV4escape <options> <args>"
}

format_time()
{
    TIME1=$1
    TIME2=$1
    TIME1=`echo $TIME1 | cut -f1 -d'.'`
    TIME2=`echo $TIME2 | cut -f2 -d'.'`
#     echo $TIME1
#     echo $TIME2
    STIME1=${#TIME1}
#     echo $STIME1
    STIME1=$(( 3 - $STIME1 ))
#     echo $STIME1
    STIME2=$(( 3 < $STIME1 ? 3 : $STIME1 ))
#     echo $STIME1
    STIME2=$(( 0 > $STIME2 ? 0 : $STIME2 ))
#     echo $STIME2
    if [ $STIME2 -eq 0 ]; then
        echo $TIME1
    else
#         echo $TIME2 | cut -c-$( echo $STIME2 )
        TIME2=`echo $TIME2 | cut -c-$( echo $STIME2)`
        echo $TIME1"."$TIME2
    fi
}

ratio_time()
{
    NUM=$1
    DEN=$2
    GT1=`echo $NUM'>'$DEN|bc -l`
    RATIO=""
    if [ $GT1 -eq 0 ]; then
        RATIO=0`echo $NUM/$DEN|bc -l`
    else
        RATIO=`echo $NUM/$DEN|bc -l`
    fi
    echo `format_time $RATIO`
}
   
##########################getting arguments
# DEGREE=$1
# EPSILONCCL=$2
# BITSIZE=$3
# STOPWHENCOMPACT=$4
# BOX=$5

while [ "$1" != "" ]; do
   PARAM=`echo $1 | sed 's/=.*//'`
   VALUE=`echo $1 | sed 's/[^=]*//; s/=//'`
   case "$PARAM" in
      -h|--help)
         usage
         exit 0
         ;;
      --degree)
        DEGREE=$VALUE
        ;;
      --epsilon)
        EPSILONCCL=$VALUE
        ;;
      --eps1)
        EPS1=$VALUE
        ;;
      --eps2)
        EPS2=$VALUE
        ;;
      --eps3)
        EPS3=$VALUE
        ;;
      --bitsize)
        BITSIZE=$VALUE
        ;;
      --nbSols)
        NBSOLS=$VALUE
        ;;
      --pow)
        POW=$VALUE
        ;;
      --itts)
        ITTS=$VALUE
        ;;
#       --stop-when-compact)
#         STOPWHENCOMPACT=1
#         ;;
      --box)
        BOX="$VALUE"
        ;;
      --purge)
        PURGE=1
        ;;
      *)
        usage
        exit 1
        ;;
    esac
    shift
done

#default values
if [ -z "$DEGREE" ]; then
   DEGREE="64"
fi

if [ -z "$EPSILONCCL" ]; then
   EPSILONCCL="-53"
fi

if [ -z "$EPS1" ]; then
   EPS1="-53"
fi

if [ -z "$EPS2" ]; then
   EPS2="-530"
fi

if [ -z "$EPS3" ]; then
   EPS3="-5300"
fi

if [ -z "$BITSIZE" ]; then
   BITSIZE="14"
fi

if [ -z "$NBSOLS" ]; then
   NBSOLS="11"
fi

if [ -z "$POW" ]; then
   POW="3"
fi

if [ -z "$ITTS" ]; then
   ITTS="4"
fi

# if [ -z "$STOPWHENCOMPACT" ]; then
#    STOPWHENCOMPACT=0
# fi

if [ -z "$BOX" ]; then
   BOX="0,1,0,1,100,1"
fi

if [ -z "$PURGE" ]; then
   PURGE=0
fi

# echo $DEGREE
# echo $EPSILONCCL
# echo $BITSIZE
# echo $STOPWHENCOMPACT
# echo $BOX
##########################constants
TRUE=1
FALSE=0
REP="tableV4V4esc"
V4FLAG=23
V4PFLAG=31
# if [ $STOPWHENCOMPACT -eq 1 ]; then
#     V3FLAG=$(( $V3FLAG + 8 ))
#     V4FLAG=$(( $V4FLAG + 8 ))
# fi

if [ -d "$REP" ]; then
  if [ $PURGE -eq 1 ]; then
    rm -rf $REP
    mkdir $REP
  fi
else
  mkdir $REP
fi

# COL_V41_TABLE=" V4', \$\epsilon = 2^{$EPS1}\$ "
# COL_V42_TABLE=" V4', \$\epsilon = 2^{$EPS2}\$ "
# COL_V43_TABLE=" V4', \$\epsilon = 2^{$EPS3}\$ "

HEAD_TABLE="\begin{tabular}{l||c|c|c||c|c|c||}"
FIRST_LINE_TABLE="&\multicolumn{3}{c||}{V4}&\multicolumn{3}{c||}{V4'}\\\\\\hline"
SECOND_LINE_TABLE="& \$2^{$EPS1}\$ & \$2^{$EPS2}\$ & \$2^{$EPS3}\$"
SECOND_LINE_TABLE=$SECOND_LINE_TABLE$SECOND_LINE_TABLE
SECOND_LINE_TABLE="\\hfill{}\$\epsilon\$ "$SECOND_LINE_TABLE"\\\\\\hline"
THIRD_LINE_TABLE="&t53 & t530/t53 & t5300/t53 &  t53 & t530/t53 & t5300/t53 \\\\\\hline\\hline"
TAIL_TAB="\end{tabular}"

TEMPTABFILE="temptabfile.txt"
rm -rf $TEMPTABFILE
touch $TEMPTABFILE

EPSS=$EPS1" "$EPS2" "$EPS3

#-----------------------------------------------bernoulli-----------------------------------------
POL_NAME="Bernoulli"
LINE_TAB="Bernoulli, \$d=$DEGREE\$"

INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4 eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" > /dev/stderr
        ./benchBernoulli $DEGREE $BOX $EPS $V4FLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4p eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" > /dev/stderr
        ./benchBernoulli $DEGREE $BOX $EPS $V4PFLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

LINE_TAB=$LINE_TAB"\\\\\\hline"
echo $LINE_TAB >> $TEMPTABFILE

#-----------------------------------------------mignotte-----------------------------------------
POL_NAME="Mignotte"
LINE_TAB="Mignotte, \$d=$DEGREE\$, $\sigma=$BITSIZE\$"
# 
INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4 eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" > /dev/stderr
        ./benchMignotte $DEGREE $BITSIZE $BOX $EPS $V4FLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4p eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" > /dev/stderr
        ./benchMignotte $DEGREE $BITSIZE $BOX $EPS $V4PFLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

LINE_TAB=$LINE_TAB"\\\\\\hline"
echo $LINE_TAB >> $TEMPTABFILE
# 
# -----------------------------------------------Wilkinson-----------------------------------------
POL_NAME="Wilkinson"
LINE_TAB="Wilkinson, \$d=$DEGREE\$"
# 
INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4 eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" > /dev/stderr
        ./benchWilkinson $DEGREE $BOX $EPS $V4FLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4p eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" > /dev/stderr
        ./benchWilkinson $DEGREE $BOX $EPS $V4PFLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

LINE_TAB=$LINE_TAB"\\\\\\hline"
echo $LINE_TAB >> $TEMPTABFILE
# 
#-----------------------------------------------Spiral-----------------------------------------
POL_NAME="Spiral"
LINE_TAB="Spiral, \$d=$DEGREE\$"
# 
INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4 eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" > /dev/stderr
        ./benchSpiral $DEGREE $BOX $EPS $V4FLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4p eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" > /dev/stderr
        ./benchSpiral $DEGREE $BOX $EPS $V4PFLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

LINE_TAB=$LINE_TAB"\\\\\\hline"
echo $LINE_TAB >> $TEMPTABFILE
# 
#-----------------------------------------------WilkMul-----------------------------------------
DEGSAVE=$DEGREE
DEGREE=$(( $NBSOLS * $(( $NBSOLS + 1 )) ))
DEGREE=$(( $DEGREE / 2 ))
# 
POL_NAME="WilkMul"
LINE_TAB="Wilkinson Mult., \$nbSols=$NBSOLS\$ (\$d=$DEGREE\$)"
# 
INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4 eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" > /dev/stderr
        ./benchWilkMul $NBSOLS $BOX $EPS $V4FLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4p eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" > /dev/stderr
        ./benchWilkMul $NBSOLS $BOX $EPS $V4PFLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

LINE_TAB=$LINE_TAB"\\\\\\hline"
echo $LINE_TAB >> $TEMPTABFILE
DEGREE=$DEGSAVE
# 
# -----------------------------------------------MignotteGen-----------------------------------------
POL_NAME="MignotteGen"
LINE_TAB="Mignotte Mult., \$d=$DEGREE\$, $\sigma=$BITSIZE\$, \$k=$POW\$"

INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4 eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" > /dev/stderr
        ./benchMignotteGen $DEGREE $BITSIZE $POW $BOX $EPS $V4FLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4p eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" > /dev/stderr
        ./benchMignotteGen $DEGREE $BITSIZE $POW $BOX $EPS $V4PFLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

LINE_TAB=$LINE_TAB"\\\\\\hline"
echo $LINE_TAB >> $TEMPTABFILE
# 
#-----------------------------------------------Cluster-----------------------------------------
DEGSAVE=$DEGREE
DEGREE=$(( 3 ** $ITTS ))
# 
POL_NAME="Cluster"
LINE_TAB="Nested Clusters, \$d=$DEGREE\$"  
INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4 eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" > /dev/stderr
        ./benchCluster $ITTS $BOX $EPS $V4FLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

INDEX=1
TREF=0
TACT=0
for EPS in $EPSS; do
    if [ ! -e $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" ]; then
        echo  "Clustering roots for $POL_NAME, degree $DEGREE version V4p eps=2^$EPS output in "$REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" > /dev/stderr
        ./benchCluster $ITTS $BOX $EPS $V4PFLAG "3" > $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"
    fi
    #old datas
#     TSV4=$(grep "tree size:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out"| cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     TDV4=$(grep -m 1 "tree depth:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
#     N4V4=$(grep -m 1 "total number NE:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':' | cut -f1 -d'|' | tr -d ' ')
    if [ $INDEX -eq 1 ]; then
        TREF=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `format_time $TREF`"
    else
        TACT=$(grep "total time:" $REP"/"$POL_NAME"_"$DEGREE"_v4p_$EPS.out" | cut -f2 -d':'| cut -f1 -d's' | cut -f1 -d'|' | tr -d ' ')
        LINE_TAB=$LINE_TAB"& `ratio_time $TACT $TREF`"
    fi
    INDEX=$(( 1 + $INDEX ))
done

LINE_TAB=$LINE_TAB"\\\\\\hline"
echo $LINE_TAB >> $TEMPTABFILE
DEGREE=$DEGSAVE
# # 
echo $HEAD_TABLE
echo $FIRST_LINE_TABLE
echo $SECOND_LINE_TABLE
echo $THIRD_LINE_TABLE
cat $TEMPTABFILE
echo $TAIL_TAB

