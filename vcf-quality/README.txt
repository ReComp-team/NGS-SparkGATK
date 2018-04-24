=== VariantQual ===

Contributor: Darren Houniet
Email: Darren.Houniet@ogt.com 

== Description ==

This set of scripts calculates the sensitivity and specificity of variant calls from an NGS analysis pipeline. They have been tested using linux OS, perl 5 version 10.1 and R version 2.15.3 and require the R packages “boot” and "stringr", which can be downloaded from CRAN (http://cran.r-project.org/). 


== Usage ==

Included are a perl (VariantQual.pl) and an R (VariantQual.r)script In order to use them, all scripts should be downloaded and placed in a single folder. 

eg. user@serverx:/home/SensSpecDirectory

The scripts can be run by executing "VariantQual.pl" with the appropriate input arguments. For example type in the directory containing the files test.vcf and VariantList_hg19.txt: 

$ perl /home/SensSpecDirectory/VariantQual.pl -vcfFile test.vcf -refSNPs VariantList_hg19.txt


== Input ==

The script requires two input files 
1) A vcf file (test.vcf in the example)
2) A file describing the variants used in the calculation (VariantList_hg19.txt in the example) This file contains one line for each of the SNPs and in each line following values (tab separated)
    (a) An (arbitrary) SNP designation. It is not used in the calculations  
    (b) The Chromosome (as chr1 to chr22) on which the SNP lies
    (c) The position of the SNP in the chromosome 
    (d) The reference allele frequencies.
Important to note is that the final column represents the frequency of the reference allele, and NOT the variant allele frequency. The chromosome designation and SNP positions should be consistent with those used in the vcf file. 



== Output ==

The programme generates a *.vcf.SenSpec.txt output file containing the sensitivity and specificity extimates: 
Sensitivity     dddd      dddd       dddd
Specificity     dddd      dddd       dddd
Where the second column represents sensitivity and specificity estimates, and the third and fourth delimit their 95% confidence intervals.





== Example ==

$ perl VariantQual.pl -h

Generates a help message.

$ VariantQual.pl -vcfFile test.vcf -refSNPs VariantList_hg19.txt

Analyses the example vcf file (test.vcf) using VariantList_hg19.txt as variant list files. This file (VariantList_hg19.txt) contains the SNPs included in HapMap that are covered by the Agilent Whole Exome (38Mb) and are also included SNPs in the Illumina 660W chip. The variant frequencies were obtained from the HapMap database (CEU population) and the coordinates transposed to hg19. 

The command should create a results file, "test.vcf.SenSpec.txt", containing:

Sensitivity	0.908308343629207	0.907556065789581	0.909293919852646
Specificity	0.995728628436051	0.995601566501509	0.995967234878748


== Disclaimer ==

These scripts which can be downloaded and used freely, but we hold NO liability for any claims, damages or other liabilities arising from the use of or in connection with these scripts.
