package uk.ac.ncl.NGS_SparkGATK.gatk_tools_parallel;

import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;

import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;

/**
 * Created by @author nicholas
 * 
 * Abstract Class that provides support methods in order to run in Spark environment GATK3.8 tools
 */
public abstract class AbstractGATKSpark {

	/**
	 * the command that calls and executes the GATK tool
	 */
	protected String gatkCommand;

	/**
	 * It expects to create a List<String> parameters, where each element corresponds to the execution of a @gatkCommand tool
	 * In particular in each element there are parameters (| separated) that should be passed to the tool
	 * 
	 * Everything is done creating a bash script (which will be removed at the end of the execution) 
	 * and this script will be used by JavaRDD.pipe("/path/script");
	 * @param sc
	 */
	abstract void run(JavaSparkContext sc);


	protected void createBashScript(String gatkCommand) {
		String bashScript = "#!/bin/bash\n" +
				"cd /\n" + 
				"while read LINE; do\n" + 
				"        IFS='|' read -a files <<< \"$LINE\"\n" + 
				"        " + gatkCommand + "\n" +
				"done\n";

		try {
			PrintWriter pw = new PrintWriter(new FileWriter(this.getClass().getSimpleName() + ".sh"));
			pw.println(bashScript);
			pw.close();

			Runtime.getRuntime().exec("chmod +x " + System.getProperty("user.dir") + "/" + this.getClass().getSimpleName() + ".sh");
		} catch (IOException ioe) { ioe.printStackTrace(); }
	}

	protected String exec(String command) {
		String line, output = "";
		try {
			ProcessBuilder builder = new ProcessBuilder(command.split(" "));
			Process process = builder.start();

			BufferedReader br = new BufferedReader(new InputStreamReader(process.getInputStream()));

			while ((line = br.readLine()) != null)
				output += line + "\n";
		} catch (IOException e) { e.printStackTrace(); }
		return output;
	}
	
	/**
	 * 
	 * @param fileName
	 * @return Path of the first occurrence in FileSystem of fileName.
	 * Prints error if there is not any fileName in FileSystem
	 */
	protected String locate(String fileName) {
		String path = this.exec("locate -br ^" + fileName + "$ -n 1").split("\n")[0];
		if(path.isEmpty())
			System.err.println("Resource not found in the File System, please provide it:\t" + fileName);
		
		return path;
	}

	/**
	 * Gathers all the instructions to execute the JavaRDD.pipe() method.
	 * In particular creates a bash script containing bash commands to execute; at the end the script is deleted
	 */
	protected void parallelPipe(JavaSparkContext sc, List<String> parameters) {
		try {
			createBashScript(this.gatkCommand);
			JavaRDD<String> bashExec = sc.parallelize(parameters)
					.pipe(System.getProperty("user.dir") + "/" + this.getClass().getSimpleName() + ".sh");

			for (String string : bashExec.collect()) 
				System.out.println(string);
		} finally {
			try { Files.delete(Paths.get(System.getProperty("user.dir") + "/" + this.getClass().getSimpleName() + ".sh")); } 
			catch (IOException x) { System.err.println(x); }
		}
	}
}