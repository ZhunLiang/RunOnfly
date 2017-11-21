#!/bin/perl
#input order: jobname gro top ratio
#like: perl main.pl 615 end_one.gro end_one.top -1_1_1
#

$RUN_MD=1;

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

system "python GetMSDpara.py";
@Ratio=GetInputPara($ARGV[3]);
@MoleName = GetMSD("NAME");
$MoleTypeNum = @MoleName;
for($i=0;$i<$MoleTypeNum;$i+=1){
  $temp = `grep -w @MoleName[$i] $ARGV[2]`;
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

system "cp grompp_Onfly.mdp grompp-4.6.mdp";
system "sed -i 's/SOLID/$SolidName/g' grompp-4.6.mdp";
system "sed -i 's/LIQUID/$LiquidName/g' grompp-4.6.mdp";

system "cp RUN.pbs run.pbs";
system "sed -i 's/JOBNAME/$ARGV[0]/g' run.pbs";

GeneraNdx($ARGV[1]);

system "mkdir onfly";
system "cp $ARGV[1] $ARGV[2] *.itp para_dens_vel.dat onfly/";
system "mv index.ndx grompp-4.6.mdp run.pbs MSD_out.dat onfly/";

if($RUN_MD==1)
{
  system "cd onfly/; grompp -f grompp-4.6.mdp -c $ARGV[1] -p $ARGV[2] -n index.ndx -o run1.tpr";
  system "cd onfly/; qsub run.pbs";
}
