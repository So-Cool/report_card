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
   *  @param  strings  Unescaped strings
   *  @return          Escaped strings
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
   *  Generate a *basic flavour* report card with given substitutions in
   *  specified temporary directory.
   *
   *  @param  fileName   Absolute path to the report card temporary directory
   *  @param  arguments  Values to be substituted in the LaTeX template
   *  @return            Absolute path to the created report card
   */
  public static String basic(String tempPath, String[] arguments) {

    // escape all LaTeX characters
    String[] escapedArguments = latexTheStrings(arguments);

    // create absolute paths
    File tempDir = new File(tempPath);
    File basicFlavour = new File(tempDir.getAbsolutePath() + File.separator +
      "rcBF.tex");

    // check if temporary directory exists
    if (!tempDir.isDirectory()) {
      System.out.println("Couldn't find temp dir: " + tempPath + "; creating!");
      tempDir.mkdir();
    }

    try {
      // Create LaTeX conversion engine
      JLRConverter converter = new JLRConverter(sourceDir);

      // Substitute LaTeX variables
      converter.replace("trialID"         , escapedArguments[0]);
      converter.replace("trialName"       , escapedArguments[1]);
      converter.replace("trialCreator"    , escapedArguments[2]);
      converter.replace("trialType"       , escapedArguments[3]);
      converter.replace("robotType"       , escapedArguments[4]);
      converter.replace("trialDescription", escapedArguments[5]);
      converter.replace("trialTime"       , escapedArguments[6]);
      converter.replace("totalTime"       , escapedArguments[7]);
      converter.replace("totalTimeFigure" , escapedArguments[8]);

      if (!converter.parse(template, basicFlavour)) {
        System.err.println(converter.getErrorMessage());
      }

      // Generate PDF in temp folder
      JLRGenerator pdfGen = new JLRGenerator();

      if (!pdfGen.generate(basicFlavour, tempDir, sourceDir)) {
        System.err.println(pdfGen.getErrorMessage());
      }

      // JLROpener.open(pdfGen.getPDF());

    } catch (IOException ex) {
      System.err.println(ex.getMessage());
    }

    // return the path to the created report card
    return tempDir.getAbsolutePath() + File.separator + "rcBF.pdf";

  }

  /**
   *  Generate a *simplistic flavour* report card with given substitutions in
   *  specified temporary directory.
   *
   *  @param  fileName   Absolute path to the report card temporary directory
   *  @param  arguments  Values to be substituted in the LaTeX template
   *  @return            Absolute path to the created report card
   */
  public static String simplistic(String fileName, String[] arguments) {

    File tempDir = new File(File.separator + "home" +
      File.separator + "knowrob" + File.separator + "temp");
    File simplisticFlavour = new File(tempDir.getAbsolutePath() +
      File.separator + "rcSF.tex");

    // check if temporary directory exists
    if (!tempDir.isDirectory()) {
      tempDir.mkdir();
    }

    // return the path to the created report card
    return tempDir.getAbsolutePath() + File.separator + "rcSF.pdf";

  }

  /**
   *  Generate a *detailed flavour* report card with given substitutions in
   *  specified temporary directory.
   *
   *  @param  fileName   Absolute path to the report card temporary directory
   *  @param  arguments  Values to be substituted in the LaTeX template
   *  @return            Absolute path to the created report card
   */
  public static String detailed(String fileName, String[] arguments) {

    File tempDir = new File(File.separator + "home" +
      File.separator + "knowrob" + File.separator + "temp");
    File detailedFlavour = new File(tempDir.getAbsolutePath() +
      File.separator + "rcDF.tex");

    // check if temporary directory exists
    if (!tempDir.isDirectory()) {
      tempDir.mkdir();
    }

    // return the path to the created report card
    return tempDir.getAbsolutePath() + File.separator + "rcDF.pdf";

  }

}
