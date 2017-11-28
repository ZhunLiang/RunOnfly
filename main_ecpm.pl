#!/bin/perl
#input order: director run_prefix gro top ratio
#like: perl main_ecpm.pl /home/lz/lz/Simulation/MoS2/build/1T-MoS2/360K/4_4_40/1T_MoS2_16.15_90_90_0/build_two/ 16.15  end_one.gro end_one.top -1_1_1

sub GeneraNdx{   #change with @Ratio,also need change .mdp file
  my ($Solid,$Liquid,$temp);
  $Solid="";
  $Liquid="";
  for($i=0;$i<$TopTypeNum;$i=$i+1){
	if(@Ratio[$i]<0){
    	$Solid="$Solid @Name_Out[$i]";
        }   
	else{
     	$Liquid="$Liquid @Name_Out[$i]";
        }  
  }
  `echo -e "r $Solid\nq" | make_ndx -f $_[0] -o index_temp.ndx`; 
  `echo -e "r $Liquid\nq" | make_ndx -f $_[0] -n index_temp.ndx -o index.ndx`;
   system "rm -f index_temp.ndx";
}

sub GetMSD{
    my @TEMP = split/\s+/,`grep $_[0] MSD_out.dat`;
    my $TEMP_num = @TEMP;
    my @Out;
    for($i=1;$i<$TEMP_num;$i=$i+1){
        $j=$i-1;
        @Out[$j] = @TEMP[$i];
    }
    return @Out;
}

sub GetInputPara{
  my @temp = split/_/,$_[0];
  return @temp;
}

if(-e $ARGV[0]){
  print "$ARGV[0]";
}
else{
  print "#----Error----#\n";
  print "No such directior: $ARGV[0]\n";
  exit();
}

system "cp GetMSDpara.py grompp_EcpmTune.mdp RUN-ecpm.pbs $ARGV[0]";
chdir $ARGV[0];
system "python GetMSDpara.py";
@Ratio=GetInputPara($ARGV[4]);
@MoleName = GetMSD("NAME");
$MoleTypeNum = @MoleName;
for($i=0;$i<$MoleTypeNum;$i+=1){
  $temp = `grep -w @MoleName[$i] $ARGV[3]`;
  if($temp){
    @Name_Out[$count] = @MoleName[$i];
    $count += 1;
  }
}

$TopTypeNum = @Name_Out;
$SolidName = "";
$LiquidName = "";
for($i=0;$i<$TopTypeNum;$i+=1){
  $temp = uc @Name_Out[$i];
  if(@Ratio[$i]<0){
    if($SolidName){
      $SolidName="$SolidName\_$temp";
    }
    else{
      $SolidName=$temp;
    }
  }
  else{
    if($LiquidName){
      $LiquidName="$LiquidName\_$temp";
    }else{
      $LiquidName=$temp;
    }
  }
}

system "cp grompp_EcpmTune.mdp grompp-ecpm.mdp";
system "sed -i 's/SOLID/$SolidName/g' grompp-ecpm.mdp";
system "sed -i 's/LIQUID/$LiquidName/g' grompp-ecpm.mdp";
GeneraNdx($ARGV[2]);

if(-e "cpm_input/"){
  system "cp cpm_input/getPot_parameters_* ./";
}
else{
  print "#---Error---\n";
  print "No cpm_input/ folder\n";
  exit();
}

$para_prefix="getPot_parameters_*.dat";
@para_files=<{$para_prefix}>;
foreach $para_file(@para_files){
  @temp1=split/getPot\_parameters\_/,$para_file;
  @temp2=split/\.dat/,@temp1[1];
  $folder_name=@temp2[0];
  $job_name="$ARGV[1]-$folder_name";
  system "mkdir $folder_name";
  system "cp RUN-ecpm.pbs run-ecpm.pbs";
  system "sed -i 's/JOBNAME/$job_name/g' run-ecpm.pbs";
  system "cp *.itp index.ndx $ARGV[2] $ARGV[3] grompp-ecpm.mdp para_dens_vel.dat run-ecpm.pbs $folder_name";
  system "mv $para_file $folder_name/getPot_parameters.dat";
  system "cp cpm_input/CPM_control.dat cpm_input/inv_MatrixA.dat $folder_name";
}

system "rm -f rm -f GetMSDpara.py grompp-ecpm.mdp grompp_EcpmTune.mdp MSD_out.dat run-ecpm.pbs RUN-ecpm.pbs index.ndx";
