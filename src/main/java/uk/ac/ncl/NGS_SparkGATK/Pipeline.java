package uk.ac.ncl.NGS_SparkGATK;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaSparkContext;

import uk.ac.ncl.NGS_SparkGATK.gatk_tools_parallel.AbstractGATKSpark;
import uk.ac.ncl.NGS_SparkGATK.gatk_tools_parallel.CallsetRefinement;
import uk.ac.ncl.NGS_SparkGATK.gatk_tools_parallel.FastqToSam;
import uk.ac.ncl.NGS_SparkGATK.gatk_tools_parallel.HelloWorld;
import uk.ac.ncl.NGS_SparkGATK.gatk_tools_parallel.VariantDiscovery;


/**
 * Created by Nicholas
 */
public class Pipeline {

	private String tool;
	private String picardPath;
	private String gatkPath;
	private String inFiles;			//specify files path in "/path/file1,/path/file2.."
	private String referenceFolder;	//3
	private String knownSites;
	private String outFolder;

	private String[] arguments;


	//testing FastqToSam
	public Pipeline(String tool, String picardPath, String inFiles, String outFile) {
		this.tool = tool;
		this.picardPath = picardPath;
		this.inFiles = inFiles;
		this.outFolder = outFile;
	}

	public Pipeline(String[] arguments) {
		this.arguments = arguments;
	}

	/*public Pipeline(String picardPath, String gatkPath, String inFiles, String referenceFolder, String knownSites, String outFolder) {
		this.picardPath = picardPath;
		this.gatkPath = gatkPath;
		this.inFiles = inFiles;
		this.referenceFolder = referenceFolder;
		this.knownSites = knownSites;
		this.outFolder = outFolder;
	}

	public Pipeline(String[] args) {
		this.picardPath = args[0];
		this.gatkPath = args[1];
		this.inFiles = args[2];
		this.referenceFolder = args[3];
		this.knownSites = args[4];
		this.outFolder = args[5];
	}*/

	public static void main(String[] args) {
		double startTime = System.currentTimeMillis();

		/*if(args.length < 6)
			System.err.println("Usage:\n <picard-path> <gatk-path> <path-input-file1>,<path-input-file2> <reference-folder> "
					+ "<known-sites1>,<known-sites2>,<known-sites3> <output-folder>");*/

		//		CheckArgs ca = new CheckArgs(args);
		//		if(ca.check()) {
		//			Pipeline pipeline = new Pipeline(args);
		//			pipeline.run();
		//		}

		Pipeline pipeline = new Pipeline(args);
		pipeline.run();

		/*Pipeline pipeline = new Pipeline(args[0], args[1], args[2], args[3]);
		pipeline.run();*/

		double stopTime = System.currentTimeMillis();
		double elapsedTime = (stopTime - startTime) / 1000;
		System.out.println("EXECUTION TIME:\t" + elapsedTime + "s");
	}

	private void run() {
		SparkConf conf = new SparkConf().setAppName(this.getClass().getName());
		JavaSparkContext sc = new JavaSparkContext(conf);
		
//		AbstractGATKSpark gatk = Class.forName(this.arguments[0]);
		
		switch (this.arguments[0]) {
		case "FastqToSam":
			if(this.arguments.length != 4)
				System.err.println("For FastqToSam expected "
						+ "<picardPath> (even number of fastq file paths coma seprated) <inFiles> and an <outFolder>");
			FastqToSam fts = new FastqToSam(this.arguments[1], this.arguments[2], this.arguments[3]);
			fts.run(sc);
			break;
		case "VariantDiscovery":
			if(this.arguments.length != 5)
				System.err.println("For VariantDiscovery expected <gatk3_8path> <referenceFile> (.fasta) "
						+ "<inFolder> (containing file _raw_variants.g.vcf produced by HaplotypeCaller) and an <outFolder>");
			VariantDiscovery vd = new VariantDiscovery(this.arguments[1], this.arguments[2], this.arguments[3], this.arguments[4]);
			vd.run(sc);
			break;
			//TODO delete Hello World
		case "HelloWorld":
			if(this.arguments.length != 3)
				System.err.println("For HelloWorld expected <inputFilePath> <outputFilePath>");
			HelloWorld hw = new HelloWorld(this.arguments[1], this.arguments[2]);
			hw.run(sc);
			break;
		case "CallsetRefinement":
			if(this.arguments.length != 5)
				System.err.println("For CallsetRefinement expected <gatk3_8path> <referenceFile> (.fasta) "
						+ "<inFolder> (containing file recalibrated_variants.vcf produced by VariantDiscovery) and an <outFolder>");
			CallsetRefinement cf = new CallsetRefinement(this.arguments[1], this.arguments[2], this.arguments[3], this.arguments[4]);
			cf.run(sc);
			break;
		
		default:
			System.err.println("Usage:\n"
					+ "\tFirst Parameter:\tFastqToSam\tSplitterDeNovos\tExonicFilter");
			break;
		}

		//JavaPairRDD<String, String> ubam = sc.wholeTextFiles(outFolder);

		sc.close();
		sc.stop();
	}
}