#!/bin/perl

#INPUT
#Input order: director folder_prefix .gro, .top  ratio
#like : perl bash_MoS2.sh /home/lz/lz/Simulation/MoS2/build/1T-MoS2/ 1T_MoS2_ gro top -1_1_1
#main.pl order: gro top ratio

$Dir_code=`pwd`;
chomp($Dir_code);

sub GetFolder{
    my @temp;
    if($_[0]){
        chdir $_[0];
        @folder=<{$_[1]*/}>;
        foreach $folder(@folder){
              @temp = (@temp,"$_[0]$folder");
        }
    chdir $Dir_code;
    }
    return @temp;
}

@folder=GetFolder($ARGV[0],$ARGV[1]);

foreach $folder(@folder){
    if(-e $folder){ 
      system "cp GetMSDpara.py  grompp_Onfly.mdp  main.pl  run.pbs $folder";
      chdir $folder;
      system "perl main.pl $ARGV[2] $ARGV[3] $ARGV[4]";
      system "rm -f GetMSDpara.py  grompp_Onfly.mdp  main.pl  run.pbs";
      chdir $Dir_code;}
    else{
      print "#-------ERROR-------#";
      print "$folder should be a director";
      print "#--------end--------#";
      exit();
    }
}


