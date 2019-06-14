/*
 * Generator.java
 * Copyright (c) 2015, Kacper Sokol
 *
 * All rights reserved.
 *
 * Software License Agreement (BSD License)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Universitaet Bremen nor the names of its
 *       contributors may be used to endorse or promote products derived from
 *       this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package org.knowrob.report_card;

import java.io.File;
import java.io.IOException;

import org.knowrob.utils.ros.RosUtilities;
import de.nixosoft.jlr.*;

public class Generator {

  // Get all necessary paths
  private static File sourceDir = new File(resolveRelativePath("package://" +
    "report_card/report_card/tex_templates"));
  private static File template = new File(sourceDir.getAbsolutePath() +
    File.separator + "reportCard.tex");

  /**
   *  Write hello message and check whether JLR library is accessible.
   * 
   *  @param args  main method parameters - not used
   */
  public static void main(String[] args) {
    System.out.println("Hello from org.knowrob.report_card.Generator package");
    // test JLR
    JLRGenerator pdfGen = new JLRGenerator();
  }

  /**
   *  Resolves a relative package path. Paths like `package://my_package/models`
   *  are resolved into the absolute path of the package `my_package`, plus
   *  `/models` appended.
   *
   *  @param  strRelativePath  A package path to be unwinded
   *  @return                  System specific absolute path to indicated
   *                           package component
   */
  private static String resolveRelativePath(String strRelativePath) {
    String strReturn = strRelativePath;
    
    if(strRelativePath.substring(0, 10).equals("package://")) {
      int nNextSlash = strRelativePath.indexOf('/', 11);
      String strPkg = strRelativePath.substring(10, nNextSlash);
        
      String strAbs = RosUtilities.rospackFind(strPkg);
        
      strReturn = strAbs + strRelativePath.substring(nNextSlash);
    }
    
    return strReturn;
  }

  /**
   *  Escape LaTeX special characters in all strings of the array.
   *
   *  @param  strings  Array with unescaped strings
   *  @return          Array with escaped strings
   */
  private static String[] latexTheStrings(String[] strings) {

    String[] latexedStrings = new String[strings.length];

    for(int i = 0; i < strings.length; ++i) {
          latexedStrings[i] = escapeLatexSpecialCharacters(strings[i]);
    }

    return latexedStrings;

  }

  /**
   *  Escapes LaTeX special characters: \ { } _ ^ # & $ % ~.
   *
   *  @param  laText  String to be escaped
   *  @return         Escaped string
   */
  private static String escapeLatexSpecialCharacters(String laText) {

    // the order must be preserved
    String backSlash = laText.replace("\\", "\\\\");
    String openBrace = backSlash.replace("{", "\\{");
    String closeBrace = openBrace.replace("}", "\\}");
    String underscore = closeBrace.replace("_", "\\_");
    String caret = underscore.replace("^", "\\^");
    String pound = caret.replace("#", "\\#");
    String and = pound.replace("&", "\\&");
    String dollar = and.replace("$", "\\$");
    String percent = dollar.replace("%", "\\%");
    String tilde = percent.replace("~", "\\~");

    return tilde;

  }

  /**
   *  Generate a report card with given sections inside specified temporary
   *  directory.
   *
   *  @param  tempPath   Absolute path to the report card temporary directory
   *  @param  trialID    Trial identifier extracted from log file
   *  @param  arguments  Values to be substituted in the LaTeX template -
   *                     absolute paths to report sections in particular
   *  @return            Absolute path to the created report card
   */
  public static String rc(String tempPath, String trialID, String[] arguments) {

    // do not escape LaTeX special characters as the arguments are always paths

    // create absolute paths
    File tempDir = new File(tempPath);
    File texOutput = new File(tempDir.getAbsolutePath() + File.separator +
      "rc.tex");

    // check if temporary directory exists
    if (!tempDir.isDirectory()) {
      System.out.println("Couldn't find temp dir: " + tempPath + "; creating!");
      tempDir.mkdir();
    }

    try {
      // Create LaTeX conversion engine
      JLRConverter converter = new JLRConverter(sourceDir);

      // up to 10 sections are supported ATM
      if(arguments.length > 10) {
        System.err.println("Up to 10 sections are supported at the moment; " +
          "please extend Java and LaTeX code if you need such feature.");
      }

      // Substitute LaTeX variables
      converter.replace("trialID", trialID);
      for(int i = 0; i < arguments.length; ++i) {
        converter.replace("section" + Integer.toString(i), arguments[i]);
      }
      // fill with blank conversion up to 10 LaTeX variables
      for(int i = arguments.length; i < 10; ++i) {
        converter.replace("section" + Integer.toString(i), "");
      }

      if (!converter.parse(template, texOutput)) {
        System.err.println(converter.getErrorMessage());
      }

      // Generate PDF in temp folder
      JLRGenerator pdfGen = new JLRGenerator();

      if (!pdfGen.generate(texOutput, tempDir, sourceDir)) {
        System.err.println(pdfGen.getErrorMessage());
      }

      // JLROpener.open(pdfGen.getPDF());

    } catch (IOException ex) {
      System.err.println(ex.getMessage());
    }

    // return the path to the created report card
    return tempDir.getAbsolutePath() + File.separator + "rc.pdf";

  }

  /**
   *  Generate a single section of a report card with given substitutions in
   *  specified temporary directory.
   *
   *  @param  tempPath         Absolute path to the report card temporary
   *                           directory
   *  @param  section          Section file name without .tex extension to be
   *                           used - the name must be exactly the same as in
   *                           tex_templates directory
   *  @param  arguments        Values to be substituted in the LaTeX template -
   *                           will be escaped
   *  @param  rawArguments     Values to be substituted in the LaTeX template -
   *                           will NOT be escaped
   *  @param  seqArguments     Sequences of values to be substituted in the
   *                           LaTeX template - will be escaped
   *  @param  rawSeqArguments  Sequences of values to be substituted in the
   *                           LaTeX template - will NOT be escaped
   *  @return                  Absolute path to the created report card
   */
  public static String section(String tempPath, String section,
    String[] arguments, String[] rawArguments, String[][] seqArguments,
    String[][] rawSeqArguments) {

    // up to 20 arguments per section are supported ATM
    String overError = "Up to 20 arguments per section are supported at the " +
      "moment; please extend Java and LaTeX code if you need such feature.";
    if(arguments.length > 20 || rawArguments.length > 20 ||
      seqArguments.length > 20 || rawSeqArguments.length > 20) {
      System.err.println(overError);
    }
    for(int i = 0; i < seqArguments.length; ++i) {
      if(seqArguments[i].length > 20) {
        System.err.println(overError);   
      }
    }
    for(int i = 0; i < rawSeqArguments.length; ++i) {
      if(rawSeqArguments[i].length > 20) {
        System.err.println(overError);   
      }
    }

    // escape all LaTeX characters
    String[] escapedArguments = latexTheStrings(arguments);
    String[][] escapedSeqArguments = new String[seqArguments.length][];
    for(int i = 0; i < seqArguments.length; ++i) {
      escapedSeqArguments[i] = latexTheStrings(seqArguments[i]);
    }
    
    // create absolute paths
    File tempDir = new File(tempPath);
    File texOutput = new File(tempDir.getAbsolutePath() + File.separator +
      section + ".tex");
    File sectionTemplate = new File(sourceDir.getAbsolutePath() + File.separator
      + section + ".tex");


    // check if temporary directory exists
    if (!tempDir.isDirectory()) {
      System.out.println("Couldn't find temp dir: " + tempPath + "; creating!");
      tempDir.mkdir();
    }

    try {
      // Create LaTeX conversion engine
      JLRConverter converter = new JLRConverter(sourceDir);

      // Substitute LaTeX variables
      for(int i = 0; i < escapedArguments.length; ++i) {
        converter.replace("argument" + Integer.toString(i), escapedArguments[i]);
      }
      for(int i = 0; i < rawArguments.length; ++i) {
        converter.replace("rawArgument" + Integer.toString(i), rawArguments[i]);
      }
      for(int i = 0; i < escapedSeqArguments.length; ++i) {
        converter.replace("seqArguments" + Integer.toString(i),
          escapedSeqArguments[i]);
      }
      for(int i = 0; i < rawSeqArguments.length; ++i) {
        converter.replace("rawSeqArguments" + Integer.toString(i),
          rawSeqArguments[i]);
      }

      if (!converter.parse(sectionTemplate, texOutput)) {
        System.err.println(converter.getErrorMessage());
      }

    } catch (IOException ex) {
      System.err.println(ex.getMessage());
    }

    // return the path to the created section
    return tempDir.getAbsolutePath() + File.separator + section + ".tex";

  }

}
