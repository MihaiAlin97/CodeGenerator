###Verbs->set,code,check,repeat,perform(make),wait,activate,make sure,
###Values->integers(100),strings(km/h),fahren state,floating point numbers,specific names(BDC panel)
###Keywords->state(clamp),signal,message,speed,error,CC
###Attributes->Timeout,Safety,Non-Safety
###Noise->in,from,when,where
###Points->1),1.
#Custom types for these??

###With regex check if a word falls in any of these categories
###Main functions :Parser,Lexer,Translator(Code generator),Executor
###Helper functions:isVerb,isValue,isKeyword,isAdjective,isPoint

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    .("$ScriptDirectory\Rules.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}



Add-Type @'
public class VERB
{
    public string Name;
    public string Type;
    
    public VERB(string Name){
    this.Name=Name;
    this.Type="VERB";
    }
}

public class VALUE
{
    public string Name;
    public string Type;
    
    public VALUE(string Name){
    this.Name=Name;
    this.Type="VALUE";
    }
}
public class ATTRIBUTE
{
    public string Name;
    public string Type;
    
    public ATTRIBUTE(string Name){
    this.Name=Name;
    this.Type="ATTRIBUTE";
    }
}
public class KEYWORD
{
    public string Name;
    public string Type;
    
    public KEYWORD(string Name){
    this.Name=Name;
    this.Type="KEYWORD";
    }
}
public class POINT
{
    public string Name;
    public string Type;
    
    public POINT(string Name){
    this.Name=Name;
    this.Type="POINT";
    }
}
'@

Add-Type -AssemblyName Microsoft.VisualBasic


$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

$Attributes=Get-Content -Path ("$ScriptDirectory\Dictionaries\Attributes.txt")
$Attributes=[System.Collections.ArrayList]@($Attributes -split [Environment]::NewLine)

$Keywords=Get-Content -Path ("$ScriptDirectory\Dictionaries\Keywords.txt")
$Keywords=[System.Collections.ArrayList]@($Keywords -split [Environment]::NewLine)

$Noise=Get-Content -Path ("$ScriptDirectory\Dictionaries\Noise.txt")
$Noise=[System.Collections.ArrayList]@($Noise -split [Environment]::NewLine)

$Values=Get-Content -Path ("$ScriptDirectory\Dictionaries\Values.txt")
$Values=[System.Collections.ArrayList]@($Values -split [Environment]::NewLine)

$Verbs=Get-Content -Path ("$ScriptDirectory\Dictionaries\Verbs.txt")
$Verbs=[System.Collections.ArrayList]@($Verbs -split [Environment]::NewLine)



Function Parser{

    Param([String]$text)
    $text=$text.ToUpper()
    $text=$text -replace "(?sm)(?<=^\d)\)","."
    $text=$text -replace "(?sm)(?<=^\d)\.",". "
    
    
    $text=$text.Replace("=","  ")
    $text=$text.Replace(",","  ")
    $text=$text.Replace(";","  ")
    $text=$text.Replace("\","  ")
    $text=$text.Replace("(","  ")
    $text=$text.Replace(")","  ")
    $text=$text.Replace("+","  ")

    
    

    $ProcessedText=[System.Collections.ArrayList]@($text.Split([Environment]::NewLine))
    
    for($i=0 ;$i -lt $ProcessedText.Count ;$i++){
    
    
        $ProcessedText[$i]=[System.Collections.ArrayList]@($ProcessedText[$i].Split(" "))
    }
    
    for($i=0 ;$i -lt $ProcessedText.Count ;$i++){
        for($j=0 ; $j -lt $ProcessedText[$i].Count;$j++){
    
        if($global:Noise -contains $ProcessedText[$i][$j]){$ProcessedText[$i][$j]=""}
        
        }
    }
    
    
    
    return $ProcessedText
}

Function Lexer{
#    ##TREE definition
    
#          SENTENCE
#             |
#     <--------------------------------------------------------------------------------------------------------------------->
#     INSTRUCTION                                      INSTRUCTION                 INSTRUCTION               INSTRUCTION ...
#          |                                                 |                         |                         |
#    VERB+KEYWORDi(ATTRIBUTEj)+VALUEk         VERB+KEYWORDi(ATTRIBUTEj)+VALUEk       .......
    
    Param([String]$text)
    
   
    $ParsedText=(Parser $text)
    $Instructions=[System.Collections.ArrayList]@()
    
    for( $i=0 ;$i -lt $ParsedText.Count ;$i++){
        $Instruction=[System.Collections.ArrayList]@()
        for( $j=0 ;$j -lt $ParsedText[$i].Count ;$j++){
            
         
            $tst=RObjectType $ParsedText[$i][$j]
            
            if($ParsedText[$i][$j] -ne ""){ $null=$Instruction.Add($tst) }
        
        }
        $null=$Instructions.Add($Instruction)
        
    }
    
   
    return $Instructions
    
}

Function Translator{

    Param([String]$text,[String]$secondtext)
    
    $LexedText=Lexer $text
    $Instructionset=[System.Collections.ArrayList]@(Evaluator -Instructions $LexedText -Expected $secondtext)

 
    return $Instructionset
}

Function Executor{
##Executor -text $TEXT -file 'C:\Users\uia99339\Desktop\SSTS_Gen5CI_SPD - S7.seq'


    Param([String]$file)
    
    ##xml structure for testcases
    ##SEQ->TCs->TC->ID
    ##            ->DT->LNK->V
    
    [xml]$Sequence=Get-Content -Path $file
    
    foreach($TestCase in $Sequence.SEQ.TCs.TC){
        Write-Host $TestCase.ID
       
        
        #strip rtf and obtain plain text from xml
        $rtBox1 = New-Object System.Windows.Forms.RichTextBox
        $rtBox1.Rtf = $Testcase.DI
        
		$InputField = $rtBox1.Text;
        $InputField=$InputField -replace "&#xD",""
		$InputField=$InputField -replace "&gt",""
        $InputField=$InputField -replace ";",""
        
        
        $rtBox2 = New-Object System.Windows.Forms.RichTextBox
        $rtBox2.Rtf = $Testcase.EE
        
		$ExpectedField = $rtBox2.Text;
        $ExpectedField=$ExpectedField -replace "&#xD",""
		$ExpectedField=$ExpectedField -replace "&gt",""
        $ExpectedField=$ExpectedField -replace ";",""
        
        ##if Input field in Utas is empty,then skip to next uTas TestCase
        if([string]::IsNullOrEmpty($InputField)){continue}
        
        

        
        $LinesOfCode=Translator $InputField $ExpectedField
        $FirstCounter=([int](($TestCase.Ts.T.LOCs.LOC[[int]($TestCase.Ts.T.LOCs.LOC.Count)]).LN)+1)
        
        $UseFor=("#USE_FOR:"+($TestCase.TSs.FirstChild.InnerXml).ToUpper())
        
        ##add #usefor in uTas testcase
        $SecondCounter=$FirstCounter+1
        $TestCase.Ts.T.LOCs.InnerXml=$TestCase.Ts.T.LOCs.InnerXml+"<LOC><SC></SC><C>$UseFor</C><P></P><CO></CO><LN>$FirstCounter</LN><ANI>$SecondCounter</ANI><AAI>$SecondCounter</AAI><AEI>$SecondCounter</AEI></LOC>"
        $FirstCounter++
        
        ##add comment for knowing generated parts of code
        $SecondCounter=$FirstCounter+1
        $TestCase.Ts.T.LOCs.InnerXml=$TestCase.Ts.T.LOCs.InnerXml+"<LOC><SC>skip</SC><C>###The stub below was generated from input###</C><P><a:string>###The stub below was generated from input###</a:string></P><CO>###The stub below was generated from input###</CO><LN>$FirstCounter</LN><ANI>$SecondCounter</ANI><AAI>$SecondCounter</AAI><AEI>$SecondCounter</AEI></LOC>"
        $FirstCounter++
        
        foreach($line in $LinesOfCode){
            Write-Host $line
            if($line[0] -eq "Ignore"){continue}
            $Conditions=$line[0]
            $Instruction=$line[1]
            $Comment=($line[3]+" ")
            $SecondCounter=$FirstCounter+1
            
            $Param=""
            foreach($token in $line[2]){##foreach line generated from the Input of Testcase,hardcode the generated lines inside xml
            
                $Param+="<a:string>$token</a:string>"##add parameters
                
            }
            
            $TestCase.Ts.T.LOCs.InnerXml=$TestCase.Ts.T.LOCs.InnerXml+
            "<LOC><SC>$Conditions</SC><C>$Instruction</C><P>$Param</P><CO>$Comment</CO><LN>$FirstCounter</LN><ANI>$SecondCounter</ANI><AAI>$SecondCounter</AAI><AEI>$SecondCounter</AEI></LOC>"##add each line of ode
          
           $FirstCounter++ 
            
        }
        ##close comment
        $SecondCounter=$FirstCounter+1
        $TestCase.Ts.T.LOCs.InnerXml=$TestCase.Ts.T.LOCs.InnerXml+"<LOC><SC>skip</SC><C>###The stub above was generated from input###</C><P><a:string>###The stub above was generated from input###</a:string></P><CO>###The stub above was generated from input###</CO><LN>$FirstCounter</LN><ANI>$SecondCounter</ANI><AAI>$SecondCounter</AAI><AEI>$SecondCounter</AEI></LOC>"
        $FirstCounter++
        
        ##close use for
        $SecondCounter=$FirstCounter+1
        $TestCase.Ts.T.LOCs.InnerXml=$TestCase.Ts.T.LOCs.InnerXml+"<LOC><SC></SC><C>#END_USE_FOR</C><P></P><CO></CO><LN>$FirstCounter</LN><ANI>$SecondCounter</ANI><AAI>$SecondCounter</AAI><AEI>$SecondCounter</AEI></LOC>"
        $FirstCounter++
        
        
    }
    $Sequence.Save($file)##save uTas sequence
    
}

Function RObjectType{

    Param([String]$text)
    #$Types=@('keyword','verb','attribute','value')
    $Types=@((isVerb $text),(isAttribute $text) ,(isValue $text),(isKeyword $text),(isPoint $text))
    $Min = 9999
    for( $i=0 ;$i -lt $Types.Count ;$i++){
        if(($Types[$i])[0] -lt $Min){ $Min=($Types[$i])[0];$pos=$i }
        #Write-Host $Types[$i] "    "  ($Types[$i])[0] "    " ($Types[$i])[1]
    }
    if($pos -eq 0 -and ($Types[$pos])[0] -le 2){return (New-Object VERB((($Types[$pos])[1])))}
    if($pos -eq 1 -and ($Types[$pos])[0] -le 2){return (New-Object ATTRIBUTE((($Types[$pos])[1])))}
    if($pos -eq 2 -and ($Types[$pos])[0] -le 2){return (New-Object VALUE((($Types[$pos])[1])))}
    if($pos -eq 3 -and ($Types[$pos])[0] -le 2){return (New-Object KEYWORD((($Types[$pos])[1])))}
    if($pos -eq 4 -and ($Types[$pos])[0] -le 2){return (New-Object POINT((($Types[$pos])[1])))}
    
    return (New-Object VALUE($text))
    
}

Function isVerb{

    Param([string] $text)
    ###Verbs->set,code,check,repeat,perform(make),wait,activate,make sure,
    ##check if String loosely represents 'SET' command,with max 2 other symbols between letters and max 1 on each part outside the word

    $Verbs=$global:Verbs
    $Distances=[System.Collections.ArrayList]@()
    $Min =99999
    if($text -match "^((\d*[ABCDEF]*)*)$") {return (9999,$text)}
    
    if($Verbs -contains $text){ return (0,$text)}
    
    
    for( $i=0 ;$i -lt $Verbs.Count ;$i++){
        
                $null=$Distances.Add((Measure-StringDistance -Source $Verbs[$i] -Compare $text))
                if($Distances[$i] -lt $Min){ $Min=$Distances[$i];$pos = $i}
            
    }

    return ($Distances[$pos],$Verbs[$pos])
}

Function isValue{

    Param([string] $text)
    if($text -match '(^\d+(\.?\d+)?\d*$)'){ return (0,$text)}

    return (99,$text)
}

Function isKeyword{

Param([string] $text)
###Keywords->state(clamp),signal,message,speed,error,CC

$Keywords=$global:Keywords
$Distances=[System.Collections.ArrayList]@()
$Min =99999

if($text -match "^((\d*[ABCDEF]*)*)$") {return (9999,$text)}

if($Keywords -contains $text){ return (0,$text)}

for( $i=0 ;$i -lt $Keywords.Count ;$i++){
    
            $null=$Distances.Add((Measure-StringDistance -Source $Keywords[$i] -Compare $text))
            if($Distances[$i] -lt $Min){ $Min=$Distances[$i];$pos = $i}
        
}

return ($Distances[$pos],$Keywords[$pos])
}

Function isAttribute{

    Param([string] $text)
    ###Attribute->Timeout,Safety,Non-Safety

    $Attributes=$global:Attributes
    $Distances=[System.Collections.ArrayList]@()
    $Min =99999
    
    if($text -match "^((\d*[ABCDEF]*)*)$") {return (9999,$text)}
    
    if($Attributes -contains $text){ return (0,$text)}
    
    for( $i=0 ;$i -lt $Attributes.Count ;$i++){
        
                $null=$Distances.Add((Measure-StringDistance -Source $Attributes[$i] -Compare $text))
                if($Distances[$i] -lt $Min){ $Min=$Distances[$i];$pos = $i}
            
    }

    return ($Distances[$pos],$Attributes[$pos])
}

Function isNoise{

    Param([string] $text)
    ###Noise->in,from,when,where

    $Noise=$global:Noise
    $Distances=[System.Collections.ArrayList]@()
    $Min =99999
    
    if($Noise -contains $text){ return (0,$text)}

    for( $i=0 ;$i -lt $Noise.Count ;$i++){
                Write-Host $Noise[$i]
                $null=$Distances.Add((Measure-StringDistance -Source $Noise[$i] -Compare $text))
                if($Distances[$i] -lt $Min){ $Min=$Distances[$i];$pos = $i}
            
}

return ($Distances[$pos],$Noise[$pos])

}



Function isPoint{

    Param([string] $text)
    ###Noise->in,from,when,where

    $Points=[System.Collections.ArrayList]@('1.','1)','2.','2)','3.','3)','4.','4)','5.','5)','6.','6)','7.','7)','8.','8)','9.','9)','10.','10)','11.','11)','12.','12)','13.','13)','14.','14)','15.','15)','16.','16)','17.','17)','18.','18)','19.','19)')
    $Distances=[System.Collections.ArrayList]@()
    $Min =99999
    
    if($Points -contains $text){ return (0,$text)}
    

return (9,$text)
}



function Measure-StringDistance {
    

    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([int])]
    param (
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$Source = "",
        [string]$Compare = ""
    )
    $n = $Source.Length;
    $m = $Compare.Length;
    $d = New-Object 'int[,]' $($n+1),$($m+1)
        
    if ($n -eq 0){
      return $m
	}
    if ($m -eq 0){
	    return $n
	}

	for ([int]$i = 0; $i -le $n; $i++){
        $d[$i, 0] = $i
    }
    for ([int]$j = 0; $j -le $m; $j++){
        $d[0, $j] = $j
    }

	for ([int]$i = 1; $i -le $n; $i++){
	    for ([int]$j = 1; $j -le $m; $j++){
            if ($Compare[$($j - 1)] -eq $Source[$($i - 1)]){
                $cost = 0
            }
            else{
                $cost = 1
            }
		    $d[$i, $j] = [Math]::Min([Math]::Min($($d[$($i-1), $j] + 1), $($d[$i, $($j-1)] + 1)),$($d[$($i-1), $($j-1)]+$cost))
	    }
	}
	    
    return $d[$n, $m]
}


Function GetSignalAddress{

Param ([string]  $signal)
    $regex=("(BO_\ .{1,10000}SG_\ "+$signal+")")
    
    $text=[IO.File]::ReadAllText('C:\Users\uia99339\Documents\CodeGenerator\Datafiles\Signals.DBC.txt')
    $text=$text -replace "`n",""
    
    if(($text -match $signal) -eq $false){ return "Undefined"}
    
    $Address=$text -match $regex
    if($Address -eq $false){return "Undefined"}
    $Address=$matches[0]
    $Address=$Address -match "BO_\ \d{1,4}(?!(.*BO_.*))"
    $Address=$matches[0]
    $Address=$Address -replace "BO_ ",""
    $Address=[int]$Address
    $Address=[convert]::tostring($Address,16)
    $Address=$Address.ToUpper()
    return $Address

}


Function TokenizeExpectedResult{

Param([string]$text)
    
    if(($Result -match "(?sm)(?<=^\d)\)") -eq $false -and ($Result -match "(?sm)(?<=^\d)\.") -eq $false){
        $Final=@{}
        $Final["last"]=$Result
   
    }
    
    else{
        $Result=$text -replace "(?sm)(?<=^\d)\)","."
        $Result=[regex]::split($Result,"(\d\.)")
        $Final=@{}
        for($i=0;$i -le $Result.Count;$i++){
            if(($Result[$i] -match "(?<=^\d)\.") -eq $false -and $i -eq 0){$Final["last"]=$Result[$i]}
            if(($Result[$i] -match "(?<=^\d)\.") -eq $true -and ($Result[$i+1] -match "(?<=^\d)\)") -eq $false){$Final[$Result[$i]]=$Result[$i+1]}
            
        }
        
        
    } 
    return $Final

}

Function SelectDocument{
    ##for excel and .seq

    if($args[0].equals('-SequenceFile')){
        $type='uTAS 5+ Sequence (*.seq)|*.seq';
        $LastDirectory=Split-Path ($global:SequencePaths -split "`n")[0] -Parent
        }
        
    elseif($args[0].equals('-SignalsFile')){
        $type='Vector DBC-File (*.DBC)|*.DBC';
        $LastDirectory=Split-Path ($global:SignalsPaths -split "`n")[0] -Parent
        }

    Add-Type -AssemblyName System.Windows.Forms
    Write-Host $LastDirectory;
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ ##open a windows file browser when 'Select #file' button is clicked
        InitialDirectory = $LastDirectory;
        Filter=$type;
    }

    Write-Host $type
    $null = $FileBrowser.ShowDialog()

    if($args[0].equals('-SequenceFile')){
        $global:SequenceFile = $FileBrowser.FileName;
        $global:SequencePaths=($FileBrowser.FileName+"`n"+$global:SequencePaths)
        $global:SequencePaths>>"$ScriptDirectory\Paths\SequencePaths.txt"
        #Write-Host $global:SequencePaths
    }##check if 'Select #file' button is called to select a .seq file
    
    elseif($args[0].equals('-SignalsFile')){
        $global:SignalsFile = $FileBrowser.FileName;
        $global:SignalsPaths=($FileBrowser.FileName+"`n"+$global:SignalsPaths) 
        $global:SignalsPaths>>"$ScriptDirectory\Paths\SignalsPaths.txt"
        #Write-Host $global:SignalsPaths
    }##check if 'Select #file' button is called to select a .DBC file


    


}