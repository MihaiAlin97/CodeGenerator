Function Evaluator{
Param([System.Collections.ArrayList]$Instructions,$Expected)
$InstructionSet=[System.Collections.ArrayList]@()

##tokenize EResult
$ExpectedSet=TokenizeExpectedResult $Expected
    foreach($Instruction in $Instructions){
        ##$Counter is for checking if the instruction cheks any of the conditions below;if not -> return instruction as string and put it in uTAS as comment
        $Counter=0
        
     
        
        if($Instruction[0].Type -eq 'POINT'){
            
            ##add ask_tester for previous point
            if($LastPoint){
                $BrokenPhrase=$ExpectedSet[$LastPoint].Split("`n")
                foreach($Phrase in $BrokenPhrase){
                    if([string]::IsNullOrEmpty($Phrase)){continue}
                    $Phrase=$Phrase.Substring(0,2).ToLower()+$Phrase.Substring(2)
                    $Phrase=("Is it true that "+$Phrase+"?")
                    $CODE=("no_vision","ask_tester",($Phrase),"")
                    $null=$InstructionSet.Add($CODE)
                }
            }
            if(-not($LastPoint)){
            ##if this is the last instruction before the first point,put the part before first point in expected result as parameter of ask_tester
                $BrokenPhrase=$ExpectedSet["last"].Split("`n")
                foreach($Phrase in $BrokenPhrase){
                    if([string]::IsNullOrEmpty($Phrase)){continue}
                    $Phrase=$Phrase.Substring(0,2).ToLower()+$Phrase.Substring(2)
                    $Phrase=("Is it true that "+$Phrase+"?")
                    $CODE=("no_vision","ask_tester",($Phrase),"")
                    $null=$InstructionSet.Add($CODE)
                }
            }
            
            $null=$InstructionSet.Add(("skip","","",("Point "+$Instruction[0].Name)));
            ##memorize last point
            $LastPoint=$Instruction[0].Name;
            }
        
        for($i=0;$i -lt $Instruction.Count;$i++){
            ##SET begins
            $LastVerb='SET'
            if($Instruction[$i].Name -eq 'SET'){
                
                if($Instruction[$i+1].Type -eq 'ATTRIBUTE' -and ($Instruction[$i+2].Name -eq 'STATE' -or $Instruction[$i+2].Name -eq 'CLAMP')){## set attribute state
                    $ATTRIBUTE=$Instruction[$i+1].Name
                    $CODE=("all","call_macro",('SetState_'+$Attribute),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++;
                    $i=$i+2
                }
                
                if($Instruction[$i+2].Type -eq 'ATTRIBUTE' -and ($Instruction[$i+1].Name -eq 'STATE' -or $Instruction[$i+1].Name -eq 'CLAMP')){## set state attribute
                    $ATTRIBUTE=$Instruction[$i+2].Name;
                    $CODE=("all","call_macro",('SetState_'+$Attribute),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++;
                    $i=$i+2
                    }
                    
                if($Instruction[$i+1].Name -eq "SIGNAL" -and $Instruction[$i+2].Type -eq "VALUE" -and $Instruction[$i+3].Type -eq "VALUE"){##set signal 
                    
                    if($i -ge 2){
                    if(($Instruction[$i-2].Name -eq "MSG" -or $Instruction[$i-2].Name -eq "MESSAGE") -and ($Instruction[$i-1].Type -eq "VALUE")){##if MESSAGE ADDRESS is before SET SIGNAL
                        $ADDRESS=($Instruction[$i-1].Name) -replace "H",""
                        $SIGNAL=$Instruction[$i+2].Name
                        $VALUE=$Instruction[$i+3].Name
                        $CODE=("all","set_env",(("E_"+$ADDRESS+"_"+$SIGNAL),$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++;
                        $i=$i+3
                        break
                        }
                    
                    }
                    
                    if(($Instruction[$i+4].Name -eq "MSG" -or $Instruction[$i+4].Name -eq "MESSAGE") -and ($Instruction[$i+5].Type -eq "VALUE")){##if MESSAGE ADDRESS is after SET SIGNAL
                        $ADDRESS=($Instruction[$i+5].Name) -replace "H",""
                        $SIGNAL=$Instruction[$i+2].Name
                        $VALUE=$Instruction[$i+3].Name
                        $CODE=("all","set_env",(("E_"+$ADDRESS+"_"+$SIGNAL),$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++;
                        $i=$i+5
                        break
                    }
                    
                    $ADDRESS=GetSignalAddress $Instruction[$i+2].Name
                   
                    
                    if($Address -ne "Undefined"){##if there is no MESSAGE ADDRESS after or before SET SIGNAL
                        $SIGNAL=$Instruction[$i+2].Name
                        $VALUE=$Instruction[$i+3].Name
                        
                        $CODE=("all","set_env",(("E_"+$ADDRESS+"_"+$SIGNAL),$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++
                        $i=$i+3;
                    }
                    
                    
                }
                if($Instruction[$i+1].Type -eq 'VALUE' -and $Instruction[$i+2].Type -eq 'VALUE'){
                    $ADDRESS=GetSignalAddress $Instruction[$i+1].Name
                    if($Address -ne "Undefined"){##if there is no SIGNAL after set->Set value[1] to value[2]
                        $SIGNAL=$Instruction[$i+1].Name
                        $VALUE=$Instruction[$i+2].Name
                        
                        $CODE=("all","set_env",(("E_"+$ADDRESS+"_"+$SIGNAL),$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++
                        $i=$i+2;
                    }
                }
                if($Instruction[$i+1].Name -eq 'SPEED'){
                     if($Instruction[$i+2].Type -eq 'VALUE' -and $Instruction[$i+2].Name -ne 'VALUE'){##set speed 10km
                         $VALUE=$Instruction[$i+2].Name -replace "KM/H",""
                         $VALUE=$VALUE -replace "KM",""
                         $VALUE=$VALUE -replace "KMH",""
                         $VALUE=$VALUE -replace "MPs",""
                         $VALUE=$VALUE -replace "MP",""
                         $VALUE=$VALUE -replace "MPH",""
                         $VALUE=$VALUE -replace "MP/H",""
                         $VALUE=$VALUE -replace "H",""
                         $CODE=("all","set_env",("E_1A1_V_VEH_COG",$VALUE),"")
                         $null=$InstructionSet.Add($CODE)
                         $Counter++
                         $i=$i+2;
                     }
                     if($Instruction[$i+2].Name -eq 'VALUE' -and $Instruction[$i+3].Type -eq 'VALUE'){##set speed value to 10 km
                         $VALUE=$Instruction[$i+3].Name -replace "KM/H",""
                         $VALUE=$VALUE -replace "KM",""
                         $VALUE=$VALUE -replace "KMH",""
                         $VALUE=$VALUE -replace "MPs",""
                         $VALUE=$VALUE -replace "MP",""
                         $VALUE=$VALUE -replace "MPH",""
                         $VALUE=$VALUE -replace "MP/H",""
                         $VALUE=$VALUE -replace "H",""
                         $CODE=("all","set_env",("E_1A1_V_VEH_COG",$VALUE),"")
                         $null=$InstructionSet.Add($CODE)
                         $Counter++
                         $i=$i+3;
                     }
                     
     
                }
                if($Instruction[$i+2].Name -eq 'SPEED'){
                     if($Instruction[$i+3].Type -eq 'VALUE' -and $Instruction[$i+3].Name -ne 'VALUE'){##set vehicle speed 10km
                         $VALUE=$Instruction[$i+3].Name -replace "KM/H",""
                         $VALUE=$VALUE -replace "KM",""
                         $VALUE=$VALUE -replace "KMH",""
                         $VALUE=$VALUE -replace "MPs",""
                         $VALUE=$VALUE -replace "MP",""
                         $VALUE=$VALUE -replace "MPH",""
                         $VALUE=$VALUE -replace "MP/H",""
                         $VALUE=$VALUE -replace "H",""
                         $CODE=("all","set_env",("E_1A1_V_VEH_COG",$VALUE),"")
                         $null=$InstructionSet.Add($CODE)
                         $Counter++
                         $i=$i+3;
                     }
                     if($Instruction[$i+3].Name -eq 'VALUE' -and $Instruction[$i+4].Type -eq 'VALUE'){##set vehicle speed value to 10 km
                         $VALUE=$Instruction[$i+4].Name -replace "KM/H",""
                         $VALUE=$VALUE -replace "KM",""
                         $VALUE=$VALUE -replace "KMH",""
                         $VALUE=$VALUE -replace "MPs",""
                         $VALUE=$VALUE -replace "MP",""
                         $VALUE=$VALUE -replace "MPH",""
                         $VALUE=$VALUE -replace "MP/H",""
                         $VALUE=$VALUE -replace "H",""
                         $CODE=("all","set_env",("E_1A1_V_VEH_COG",$VALUE),"")
                         $null=$InstructionSet.Add($CODE)
                         $Counter++
                         $i=$i+3;
                     }
                     
     
                }
                if($Instruction[$i+1].Name -eq 'SPEED' -or $Instruction[$i+2].Name -eq 'SPEED' -or $Instruction[$i+3].Name -eq 'SPEED'){##set speed on invalid value
                    if($Instruction[$i+1].Name -eq 'INVALID' -or $Instruction[$i+2].Name -eq 'INVALID' -or $Instruction[$i+3].Name -eq 'INVALID'){
                        [string]$VALUE=[string](Get-Random -Minimum 450 -Maximum 600)
                        $CODE=("all","set_env",("E_1A1_V_VEH_COG",$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++
                        $i=$i+3;
                    }
                    if($Instruction[$i+1].Name -eq 'INVALID' -or $Instruction[$i+2].Name -eq 'INVALID' -or $Instruction[$i+3].Name -eq 'INVALID'){##set speed on valid value
                        [string]$VALUE=[string](Get-Random -Minimum 0 -Maximum 300)
                        $CODE=("all","set_env",("E_1A1_V_VEH_COG",$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++
                        $i=$i+3;
                    }
                }
                
                
            
            }##SET ends here

            ##CODE begins here
            if($Instruction[$i].Name -eq 'CODE'){
                $LastVerb='CODE'
                if($Instruction[$i+1].Type -eq 'VALUE' -and $Instruction[$i+2].Type -eq 'VALUE'){##CODE VARIABLE VALUE
                     $VARIABLE=$Instruction[$i+1].Name
                     $VALUE=($Instruction[$i+2].Name) -replace "0X",""
                     $VALUE=$VALUE -replace "H",""
                     $VALUE=$VALUE -replace "\.",""
                     $CODE=("all","call_macro",("CODE",$VARIABLE,$VALUE),"")
                     $null=$InstructionSet.Add($CODE)
                     $Counter++
                     $i=$i+2
                     
                }
            
            }##CODE ENDS HERE
            
            
            ##Perform begins here
            if($Instruction[$i].Name -eq 'PERFORM' -or $Instruction[$i].Name -eq 'MAKE'){
                $LastVerb='PERFORM'
                if($Instruction[$i+1].Name -eq 'CLAMP' -or $Instruction[$i+1].Name -eq 'STATE'){##perform/make a state/clamp switch
                    if($Instruction[$i+2].Name -eq 'SWITCH'){
                        if($Instruction[$i+3].Type -eq 'ATTRIBUTE'){
                            $Attribute=$Instruction[$i+3].Name
                            $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                            if($Instruction[$i+3].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                            else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                            
                            if($Instruction[$i+4].Type -eq 'ATTRIBUTE' ){ 
                                $Attribute=$Instruction[$i+4].Name
                                $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                if($Instruction[$i+4].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                                
                                if($Instruction[$i+5].Type -eq 'ATTRIBUTE' ){ 
                                    $Attribute=$Instruction[$i+5].Name
                                    $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                    if($Instruction[$i+5].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                    else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                                    
                                    if($Instruction[$i+6].Type -eq 'ATTRIBUTE' ){
                                        $Attribute=$Instruction[$i+6].Name
                                        $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                        if($Instruction[$i+6].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                        else{$null=$InstructionSet.Add(("all","delay",("5000"),""))} 
                                        
                                        if($Instruction[$i+7].Type -eq 'ATTRIBUTE' ){
                                            $Attribute=$Instruction[$i+7].Name
                                            $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                            if($Instruction[$i+7].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                            else{$null=$InstructionSet.Add(("all","delay",("5000"),""))} 
                                            
                                            if($Instruction[$i+8].Type -eq 'ATTRIBUTE' ){ 
                                                $Attribute=$Instruction[$i+8].Name
                                                $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                                if($Instruction[$i+8].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                                else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                                                
                                                if($Instruction[$i+9].Type -eq 'ATTRIBUTE' ){ 
                                                    $Attribute=$Instruction[$i+9].Name
                                                    $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                                    if($Instruction[$i+9].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                                    else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                                                    
                                                    if($Instruction[$i+10].Type -eq 'ATTRIBUTE' ){
                                                        $Attribute=$Instruction[$i+10].Name
                                                        $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                                        if($Instruction[$i+10].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                                        else{$null=$InstructionSet.Add(("all","delay",("5000"),""))} 
                                                        $i=$i+10
                                                    }else{$i=$i+9}  
                                                }else{$i=$i+8}
                                            }else{$i=$i+7}
                                        }else{$i=$i+6}
                                    } else{$i=$i+5} 
                                }else{$i=$i+4}   
                            
                            } else{$i=$i+3}  
                        
                        }
                    }
                }  
                ##first big if ends here
                if($Instruction[$i+1].Name -eq 'SWITCH'){##perform/make a  switch state/clamp
                    if($Instruction[$i+2].Name -eq 'CLAMP' -or $Instruction[$i+2].Name -eq 'STATE'){
                        if($Instruction[$i+3].Type -eq 'ATTRIBUTE'){
                            $Attribute=$Instruction[$i+3].Name
                            $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                            if($Instruction[$i+3].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                            else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                            
                            if($Instruction[$i+4].Type -eq 'ATTRIBUTE' ){ 
                                $Attribute=$Instruction[$i+4].Name
                                $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                if($Instruction[$i+4].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                                
                                if($Instruction[$i+5].Type -eq 'ATTRIBUTE' ){ 
                                    $Attribute=$Instruction[$i+5].Name
                                    $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                    if($Instruction[$i+5].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                    else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                                    
                                    if($Instruction[$i+6].Type -eq 'ATTRIBUTE' ){
                                        $Attribute=$Instruction[$i+6].Name
                                        $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                        if($Instruction[$i+6].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                        else{$null=$InstructionSet.Add(("all","delay",("5000"),""))} 
                                        
                                        if($Instruction[$i+7].Type -eq 'ATTRIBUTE' ){
                                            $Attribute=$Instruction[$i+7].Name
                                            $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                            if($Instruction[$i+7].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                            else{$null=$InstructionSet.Add(("all","delay",("5000"),""))} 
                                            
                                            if($Instruction[$i+8].Type -eq 'ATTRIBUTE' ){ 
                                                $Attribute=$Instruction[$i+8].Name
                                                $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                                if($Instruction[$i+8].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                                else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                                                
                                                if($Instruction[$i+9].Type -eq 'ATTRIBUTE' ){ 
                                                    $Attribute=$Instruction[$i+9].Name
                                                    $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                                    if($Instruction[$i+9].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                                    else{$null=$InstructionSet.Add(("all","delay",("5000"),""))}
                                                    
                                                    if($Instruction[$i+10].Type -eq 'ATTRIBUTE' ){
                                                        $Attribute=$Instruction[$i+10].Name
                                                        $null=$InstructionSet.Add(("all","call_macro",('SetState_'+$Attribute),""))
                                                        if($Instruction[$i+10].Name -eq "PARKEN"){$null=$InstructionSet.Add(("all","delay",("3000"),""))}
                                                        else{$null=$InstructionSet.Add(("all","delay",("5000"),""))} 
                                                        $i=$i+10
                                                    }else{$i=$i+9}  
                                                }else{$i=$i+8}
                                            }else{$i=$i+7}
                                        }else{$i=$i+6}
                                    } else{$i=$i+5} 
                                }else{$i=$i+4}   
                            
                            } else{$i=$i+3}  
                        
                        }
                    }
                }
                
                                 
                    
            
            }##PERFORM ENDS HERE
            
            ##ACTIVATE begins here
            if($Instruction[$i].Name -eq 'ACTIVATE'){
                $LastVerb='ACTIVATE'
                
                ##SAFETY CC begins here
                if($Instruction[$i+1].Name -eq 'SAFETY' -and $Instruction[$i+2].Name -eq 'CC' -and $Instruction[$i+3].Name -eq 'EG' -and $Instruction[$i+4].Name -match "^((\d+[D]?\.?))$"){##ACTIVATE SAFETY CC(EG 432D)
                     $VALUE=($Instruction[$i+4].Name) -replace "\.",""
                     $VALUE=$VALUE -replace "D",""
                     $CODE=("all","call_macro",("CC_Activate",$VALUE),"")
                     $null=$InstructionSet.Add($CODE)
                     
                     $Counter++
                     $i=$i+4  
                }
                if($Instruction[$i+1].Name -eq 'SAFETY' -and $Instruction[$i+2].Name -eq 'CC' -and $Instruction[$i+3].Name -match "^((\d+[D]?\.?))$"){##ACTIVATE SAFETY CC(432D)
                     $VALUE=($Instruction[$i+3].Name) -replace "\.",""
                     $VALUE=$VALUE -replace "D",""
                     $CODE=("all","call_macro",("CC_Activate",$VALUE),"")
                     $null=$InstructionSet.Add($CODE)

                     $Counter++
                     $i=$i+3 
                }   
                
                if($Instruction[$i+1].Name -eq 'SAFETY' -and $Instruction[$i+2].Name -eq 'CC' -and $Instruction[$i+3].Name -eq 'ID' -and $Instruction[$i+4].Name -eq 'EG' -and $Instruction[$i+5].Name -match "^((\d+[D]?\.?))$"){##ACTIVATE SAFETY CC ID(EG 432D)
                     $VALUE=($Instruction[$i+5].Name) -replace "\.",""
                     $VALUE=$VALUE -replace "D",""
                     $CODE=("all","call_macro",("CC_Activate",$VALUE),"")
                     $null=$InstructionSet.Add($CODE)

                     $Counter++
                     $i=$i+5 
                }
                if($Instruction[$i+1].Name -eq 'SAFETY' -and $Instruction[$i+2].Name -eq 'CC' -and $Instruction[$i+3].Name -eq 'ID' -and $Instruction[$i+4].Name -match "^((\d+[D]?\.?))$"){##ACTIVATE SAFETY CC ID(432D)
                     $VALUE=($Instruction[$i+4].Name) -replace "\.",""
                     $VALUE=$VALUE -replace "D",""
                     $CODE=("all","call_macro",("CC_Activate",$VALUE),"")
                     $null=$InstructionSet.Add($CODE)

                     $Counter++
                     $i=$i+4 
                }##SAFETY CC ends here
                
                ##NON-SAFETY CC begins here
                if($Instruction[$i+1].Name -eq 'NON-SAFETY' -and $Instruction[$i+2].Name -eq 'CC' -and $Instruction[$i+3].Name -eq 'EG' -and $Instruction[$i+4].Name -match "^((\d+[D]?\.?))$"){##ACTIVATE NON-SAFETY CC(EG 432D)
                     $VALUE=($Instruction[$i+4].Name) -replace "\.",""
                     $VALUE=$VALUE -replace "D",""
                     $CODE=("all","call_macro",("CC_Activate",$VALUE),"")
                     $null=$InstructionSet.Add($CODE)
                     
                     $Counter++
                     $i=$i+4  
                }
                if($Instruction[$i+1].Name -eq 'NON-SAFETY' -and $Instruction[$i+2].Name -eq 'CC' -and $Instruction[$i+3].Name -match "^((\d+[D]?\.?))$"){##ACTIVATE NON-SAFETY CC(432D)
                     $VALUE=($Instruction[$i+3].Name) -replace "\.",""
                     $VALUE=$VALUE -replace "D",""
                     $CODE=("all","call_macro",("CC_Activate",$VALUE),"")
                     $null=$InstructionSet.Add($CODE)

                     $Counter++
                     $i=$i+3 
                }   
                
                if($Instruction[$i+1].Name -eq 'NON-SAFETY' -and $Instruction[$i+2].Name -eq 'CC' -and $Instruction[$i+3].Name -eq 'ID' -and $Instruction[$i+4].Name -eq 'EG' -and $Instruction[$i+5].Name -match "^((\d+[D]?\.?))$"){##ACTIVATE NON-SAFETY CC ID(EG 432D)
                     $VALUE=($Instruction[$i+5].Name) -replace "\.",""
                     $VALUE=$VALUE -replace "D",""
                     $CODE=("all","call_macro",("CC_Activate",$VALUE),"")
                     $null=$InstructionSet.Add($CODE)

                     $Counter++
                     $i=$i+5 
                }
                if($Instruction[$i+1].Name -eq 'NON-SAFETY' -and $Instruction[$i+2].Name -eq 'CC' -and $Instruction[$i+3].Name -eq 'ID' -and $Instruction[$i+4].Name -match "^((\d+[D]?\.?))$"){##ACTIVATE NON-SAFETY CC ID(432D)
                     $VALUE=($Instruction[$i+4].Name) -replace "\.",""
                     $VALUE=$VALUE -replace "D",""
                     $CODE=("all","call_macro",("CC_Activate",$VALUE),"")
                     $null=$InstructionSet.Add($CODE)

                     $Counter++
                     $i=$i+4 
                }##NON-SAFETY CC ends here
                
            }##ACTIVATE ends here
            
            ##DEACTIVATE begins here
            if($Instruction[$i].Name -eq 'DEACTIVATE'){
                $LastVerb='DEACTIVATE'
                if($Instruction[$i+1].Name -eq "CC"){##Deactivate CC
                    $CODE=("all","delay",("2000"),"")
                    $null=$InstructionSet.Add($CODE)
                    $CODE=("all","call_macro",("CC_Deactivate"),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+1
                }
                if($Instruction[$i+1].Name -eq "SAFETY" -and $Instruction[$i+2].Name -eq "CC"){##Deactivate SAFETY CC
                    $CODE=("all","delay",("2000"),"")
                    $null=$InstructionSet.Add($CODE)
                    $CODE=("all","call_macro",("CC_Deactivate"),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+2 
                }
                if($Instruction[$i+1].Name -eq "NON-SAFETY" -and $Instruction[$i+2].Name -eq "CC"){##Deactivate SAFETY CC
                    $CODE=("all","delay",("2000"),"")
                    $null=$InstructionSet.Add($CODE)
                    $CODE=("all","call_macro",("CC_Deactivate"),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+2 
                }
                if($Instruction[$i+1].Name -eq "HUD"){##Deactivate HUD
                    $CODE=("all","set_env",("E_321_OP_SLCTN_DISP_HUD_3","0"),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+1
                }
                
            }##DEACTIVATE ends here
            
            ##WAIT begins here
            if($Instruction[$i].Name -eq 'WAIT'){
                $LastVerb='WAIT'
                if($Instruction[$i+1].Type -eq 'VALUE' -and $Instruction[$i+2].Type -eq 'KEYWORD' -and $Instruction[$i+2].Name -eq 'SECOND'  ){#WAIT 3 se
                    $VALUE=($Instruction[$i+1].Name+"000")
                    $CODE=("all","delay",($VALUE),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+2
                }
                if($Instruction[$i+1].Type -eq 'VALUE' -and $Instruction[$i+2].Type -eq 'KEYWORD' -and $Instruction[$i+2].Name -eq 'MINUTE'  ){#WAIT 3 min
                    $VALUE=([string]([int]$Instruction[$i+1].Name*60)+"000")
                    $CODE=("all","delay",($VALUE),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+2
                }
                if($Instruction[$i+1].Type -eq 'VALUE' -and $Instruction[$i+2].Type -eq 'KEYWORD' -and $Instruction[$i+2].Name -eq 'HOUR'  ){#WAIT 3 hrs
                    $VALUE=([string]([int]$Instruction[$i+1].Name*3600)+"000")
                    $CODE=("all","delay",($VALUE),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+2
                }
                if($Instruction[$i+2].Name -ne 'SECOND' -and $Instruction[$i+2].Name -ne 'MINUTE' -and $Instruction[$i+2].Name -ne 'HOUR' ){#WAIT 
                    $CODE=("all","delay",("3000"),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+2
                }
            }
            
            ##the following part is for special instructions(ex:those who have no verb in them,or the use of verb is nonconcludent with keywords or values)
            if($Instruction[$i].Type -eq 'VALUE' -and ($i+1) -le $Instruction.Count -and (($Instruction[$i].Name)[0]+($Instruction[$i].Name)[1]) -ne "E_" -and ($Instruction[$i].Name -match "^([A-Z\d]*_[A-Z\d]+([A-Z\d]*_[A-Z\d]+)*)$") -eq $true){##VA_RIA_BLE VALUE
                $NEXTVALUE=$Instruction[$i+1].Name
                $NEXTVALUE=$NEXTVALUE -replace "0X",""
                $NEXTVALUE=$NEXTVALUE -replace "H",""
                $NEXTVALUE=$NEXTVALUE -replace "\.",""
                
                if(($NEXTVALUE -match "^((\d*[ABCDEF]*)*)$") -eq $true){##if value after signal or variable exists(is dec or hex )
                    $ADDRESS=GetSignalAddress $Instruction[$i].Name
                    if($ADDRESS -eq "Undefined"){##if is variable
                        $VARIABLE=$Instruction[$i].Name
                        $VALUE=$NEXTVALUE
                        $CODE=("all","call_macro",("CODE",$VARIABLE,$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++
                        $i=$i+1      
                    }
                    if( $ADDRESS -ne "Undefined"){##if is signal
                        $VARIABLE=$Instruction[$i].Name
                        $VALUE=$NEXTVALUE
                        $CODE=("all","set_env",(("E_"+$ADDRESS+"_"+$VARIABLE),$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++
                        $i=$i+1      
                    }
               }
               if(($NEXTVALUE -match "^((\d*[ABCDEF]*)*)$") -eq $false){##if value after signal or variable exists(is dec or hex )
               
                    $ADDRESS=GetSignalAddress $Instruction[$i].Name
                    if( $ADDRESS -eq "Undefined"){##if is variable
                        $VARIABLE=$Instruction[$i].Name
                        $VALUE="01"
                        $CODE=("all","call_macro",("CODE",$VARIABLE,$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++
                        $i=$i+1      
                    }
                    if( $ADDRESS -ne "Undefined"){##if is signal
                        $VARIABLE=$Instruction[$i].Name
                        $VALUE="01"
                        $CODE=("all","set_env",(("E_"+$ADDRESS+"_"+$VARIABLE),$VALUE),"")
                        $null=$InstructionSet.Add($CODE)
                        $Counter++
                        $i=$i+1      
                    }
               }     
            }
            
            if($Instruction[$i].Type -eq 'VALUE' -and (($Instruction[$i].Name)[0]+($Instruction[$i].Name)[1]) -eq "E_" -and $Instruction[$i+1].Type -eq 'VALUE'){##E_SIGNAL = 1 or E_SIGNAL empty_space
                
                $NEXTVALUE=$Instruction[$i+1].Name
                $NEXTVALUE=$NEXTVALUE -replace "0X",""
                $NEXTVALUE=$NEXTVALUE -replace "H",""
                $NEXTVALUE=$NEXTVALUE -replace "\.",""
                
                if(($NEXTVALUE -match "^((\d*[ABCDEF]*)*)$") -eq $false){ ##E_SIGNAL empty_space
                    $VARIABLE=$Instruction[$i].Name
                    $VALUE="01"
                    $CODE=("all","set_env",($VARIABLE,$VALUE),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+1  
                } 
                if(($NEXTVALUE -match "^((\d*[ABCDEF]*)*)$") -eq $true){##E_SIGNAL = 1
                    $VARIABLE=$Instruction[$i].Name
                    $VALUE=$NEXTVALUE
                    $CODE=("all","set_env",($VARIABLE,$VALUE),"")
                    $null=$InstructionSet.Add($CODE)
                    $Counter++
                    $i=$i+1  
                }        
            }
            
        
        }##for ends here
        
        ##this if it's for the last point in expected result;if index of instruction is the last index,then generate code for the point
        if(($Instructions.IndexOf($Instruction)) -eq ($Instructions.Count-1) ){
        $BrokenPhrase=$ExpectedSet[$LastPoint].Split("`n")
        foreach($Phrase in $BrokenPhrase){
                    if([string]::IsNullOrEmpty($Phrase)){continue}
                    $Phrase=$Phrase.Substring(0,2).ToLower()+$Phrase.Substring(2)
                    $Phrase=("Is it true that "+$Phrase+"?")
                    $CODE=("no_vision","ask_tester",($Phrase),"")
                    $null=$InstructionSet.Add($CODE)
                }            
        }
        
        if($Counter -eq 0 -and $Instruction -ne $null ){##if instruction does not match any if,return it as
            $COMMENT=""
            for($k=0;$k -lt $Instruction.Count;$k++){
                
                $COMMENT+=$Instruction[$k].Name
            }
            $CODE=("skip","","",$COMMENT)
            $null=$InstructionSet.Add($CODE)
            $Counter=0
            
        }
    }##second for ends here    
    
    $null=$InstructionSet.Add(("Ignore","","",""))
    return $InstructionSet
}