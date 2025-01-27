
# Function to assess significance as to whether sample appears to have undergone genome doubling
# input:
# sample           - unique sample name
# seg.mat.minor    - segmented matrix with minor allele (e.g. seg.mat.LOH)
#                  - columns should be as follows: c("Sample","Chrom","Start","End","Num.probes","val")
# seg.mat.copy     - segmented total copy number matrix (columns as above)
# number.of.sim    - number of random simulations required;
# the function returns a p.val for every sample
# the function uses the limma weighted.median function

# 
# According to the code of clonality.estimation(), "val" means "cn".

#' genome.doub.sig
#' @param sample TCGA sample identifier
#' @param seg.mat.minor segmented minor allele copy number matrix. segmented matrix with minor allele (e.g. seg.mat.LOH). columns should be as follows: c("Sample","Chrom","Start","End","Num.probes","val")
#' @param seg.mat.copy segmented total copy number matrix. segmented total copy number matrix (columns as above)
#' @param number.of.sim The number of simulations to assess genome doubling likelihood, defaults to 10,000
#' @description 
#' The following function estimates the probability that a genome doubling has
#' occured at some point during the evolutionary history of a tumour. This function is to assess significance as to whether sample appears to have undergone genome doubling.
#' 
#' @details 
#' According to the code of clonality.estimation(), "val" means "cn". the function uses the limma weighted.median function
#' @return
#' the function returns a p.val for every sample
#' 
#' @export
#'
#' @examples
#' genome.doub.sig(sample, seg.mat.minor, seg.mat.copy, number.of.sim = 10000)
#' 
genome.doub.sig <- function(sample, seg.mat.minor, seg.mat.copy, number.of.sim = 10000) {
  # Remove other samples:
  sub.minor <- subset(seg.mat.minor, seg.mat.minor[, 1] == sample)
  sub.major <- subset(seg.mat.copy, seg.mat.copy[, 1] == sample)

  # define expected chr names
  chr.names <- c(
    "1", "1.5", "2", "2.5", "3", "3.5", "4", "4.5", "5", "5.5", "6", "6.5", "7", "7.5", "8", "8.5", "9",
    "9.5", "10", "10.5", "11", "11.5", "12", "12.5", "13.5", "14.5", "15.5", "16", "16.5", "17",
    "17.5", "18", "18.5", "19", "19.5", "20", "20.5", "21.5", "22.5"
  )

  # example:
  #       1        2         3            4             5         6
  #  Sample    Chrom     Start          End    Num.probes       val
  # sample1        1     14930    249212400            NA         1
  # sample1        2     41686    242192881            NA         1
  # sample1        3    361508     46620600            NA         1
  # sample1        3  46620900     52823700            NA         1
  # sample1        3  52824924    197896700            NA         1
  # sample1        4     53500    190905700            NA         1

  # Determine whether given chromosome names are not equal to expected
  # note: input from ASCAT or ABSOLUTE must be modified (chromosome arms must be listed)
  # 1. check minor chromosomes
  check_chrom_res <- check_chromosomal_names(
    input_chrom = sub.minor[, 2]
    , target_chrom = chr.names
  )
  if (check_chrom_res == "missing") {
    warning("Some chromosomes are missing in seg.mat.minor")
  } else if (check_chrom_res != "identical") {
    stop(c(("seg.mat.minor chr.names!= expected chr.names")))
  }
  # 2. check total chromosomes
  check_chrom_res <- check_chromosomal_names(
    input_chrom = sub.major[, 2]
    , target_chrom = chr.names
  )
  if (check_chrom_res == "missing") {
    warning("Some chromosomes are missing in seg.mat.copy")
  } else if (check_chrom_res != "identical") {
    stop(c(("seg.mat.copy chr.names!= expected chr.names")))
  }
  
  # summarize minor allele copy numbers at chromosome arm.level
  chr.arm.ploidy.minor <- c()

  for (chr.arm in unique(sub.minor[, 2])) {
    sub.chr.minor <- rbind(subset(sub.minor, sub.minor[, 2] == chr.arm)[, 2:6])
    sub.chr.minor <- apply(sub.chr.minor, 2, as.numeric)
    sub.chr.minor <- rbind(sub.chr.minor)

    if (length(unique(sub.chr.minor[, 5])) == 1) {
      arm.ploidy <- unique(sub.chr.minor[, 5])
    } else if (length(unique(sub.chr.minor[, 5])) > 1) {
      arm.ploidy <- limma::weighted.median(sub.chr.minor[, 5], w = sub.chr.minor[, 3] - sub.chr.minor[, 2], na.rm = TRUE)
    }

    chr.arm.ploidy.minor <- c(chr.arm.ploidy.minor, arm.ploidy)
  }

  names(chr.arm.ploidy.minor) <- unique(sub.minor[, 2])

  # summarize total copy number at chromosome arm level
  # note: major allele will be calculated by subtracting minor from total
  chr.arm.ploidy.major <- c()

  for (chr.arm in unique(sub.major[, 2])) {
    sub.chr.major <- rbind(subset(sub.major, sub.major[, 2] == chr.arm)[, 2:6])
    sub.chr.major <- apply(sub.chr.major, 2, as.numeric)
    sub.chr.major <- rbind(sub.chr.major)

    if (length(unique(sub.chr.major[, 5])) == 1) {
      arm.ploidy <- unique(sub.chr.major[, 5])
    }

    else if (length(unique(sub.chr.major[, 5])) > 1) {
      arm.ploidy <- limma::weighted.median(sub.chr.major[, 5], w = sub.chr.major[, 3] - sub.chr.major[, 2], na.rm = T)
    }

    chr.arm.ploidy.major <- c(chr.arm.ploidy.major, arm.ploidy)
  }
  names(chr.arm.ploidy.major) <- unique(sub.major[, 2])

  # major from total and minor
  chr.arm.ploidy.major <- chr.arm.ploidy.major - chr.arm.ploidy.minor

  # calculate the total gains and losses
  total.aber <- sum(abs(chr.arm.ploidy.minor - 1)) + sum(abs(chr.arm.ploidy.major - 1))

  chr.probs <- c()

  # if no aberrations, cannot estimate GD; will assume no GD
  if (sum(total.aber) == 0) {
    p.val.genome.doubl <- c(1)
  }

  if (sum(total.aber) != 0) {
    # calculate the probability loss and gain for every arm
    for (chr.arm in chr.names) {
      chr.prob.A <- (chr.arm.ploidy.major[chr.arm] - 1)
      chr.prob.A <- c(
        sum(chr.prob.A[chr.prob.A > 0]) / total.aber,
        abs(sum(chr.prob.A[chr.prob.A < 0]) / total.aber)
      )
      names(chr.prob.A) <- c(paste(chr.arm, "_Again", sep = ""), paste(chr.arm, "_Aloss", sep = ""))

      chr.prob.B <- (chr.arm.ploidy.minor[chr.arm] - 1)
      chr.prob.B <- c(sum(chr.prob.B[chr.prob.B > 0]) / total.aber, abs(sum(chr.prob.B[chr.prob.B < 0]) / total.aber))
      names(chr.prob.B) <- c(paste(chr.arm, "_Bgain", sep = ""), paste(chr.arm, "_Bloss", sep = ""))

      chr.prob <- c(chr.prob.A, chr.prob.B)

      chr.probs <- c(chr.probs, chr.prob)
    }
    
    
    #The observed proportion of chromosome arms with a major allele copy number (MCN) >=2 (duplicated genomes)
    prop.major.even.obs <- length(which(chr.arm.ploidy.major >= 2)) / length(chr.arm.ploidy.major)
    # should probably set something as prop.major.even.obs p.val =0.001

    prop.major.even.sim <- c()
    k <- 1
    while (k <= number.of.sim) {
      chr.sim <- table(sample(names(chr.probs), total.aber, prob = chr.probs, replace = T))
      chr.sim.table <- chr.probs
      chr.sim.table <- rep(0, length(chr.probs))
      names(chr.sim.table) <- names(chr.probs)
      chr.sim.table[names(chr.sim)] <- chr.sim
      chr.sim.table <- cbind(
        chr.sim.table[seq(1, length(chr.sim.table), by = 4)],
        chr.sim.table[seq(2, length(chr.sim.table), by = 4)],
        chr.sim.table[seq(3, length(chr.sim.table), by = 4)],
        chr.sim.table[seq(4, length(chr.sim.table), by = 4)]
      )

      rownames(chr.sim.table) <- chr.names
      colnames(chr.sim.table) <- c("gain.A", "loss.A", "gain.B", "loss.B")
      
      #       gain.A  loss.A  gain.B  loss.B
      #1        0      0      0       0
      #1.5      2      0      1       0
      #2        0      0      1       0
      
      #Get the simulated majors.
      chr.sim.major <- apply(cbind(
        c(1 + chr.sim.table[, 1] - chr.sim.table[, 2]),
        c(1 + chr.sim.table[, 3] - chr.sim.table[, 4])
      ), 1, max)


      prop.major.even <- length(which(chr.sim.major >= 2)) / length(chr.sim.major)

      prop.major.even.sim <- c(prop.major.even.sim, prop.major.even)

      k <- k + 1
    }

    p.val.genome.doubl <- length(which(prop.major.even.sim >= prop.major.even.obs)) / number.of.sim
    # note, will give p=0 if no simulation is greater than observed (i.e. technically incorrect)
    if (prop.major.even.obs == 1) {
      p.val.genome.doubl <- 0
    }
  }
  
  if (sum(total.aber) != 0) {
    
      list(
        prop.major.even.sim = prop.major.even.sim,
        prop.major.even.obs = prop.major.even.obs,
        pval = p.val.genome.doubl
      )
    
  }else{
    
    list(
        prop.major.even.sim = NA,
        prop.major.even.obs = 0,
        pval = 1
      )
    
  }
}

#' fun.GD.status
#' 
#' @export
fun.GD.status <- function(GD.pval, ploidy.val) {
  GD.status <- c(NA)

  # is the patient diploid
  if (ploidy.val <= 2) {
    GD.status <- ifelse(GD.pval <= 0.001, "GD", "nGD")
  }

  # is the patient triploid
  if (ploidy.val == 3) {
    GD.status <- ifelse(GD.pval <= 0.001, "GD", "nGD")
  }

  # is the patient tetraploid
  if (ploidy.val == 4) {
    GD.status <- ifelse(GD.pval <= 0.05, "GD", "nGD")
  }

  # is the patient pentaploid
  if (ploidy.val == 5) {
    GD.status <- ifelse(GD.pval <= 0.5, "GD", "nGD")
  }
  # is the patient hexaploid
  if (ploidy.val == 6) {
    GD.status <- ifelse(GD.pval <= 1, "GD", "nGD")
  }

  # Handle larger values of ploidy
  if (ploidy.val > 6) {
    GD.status <- ifelse(GD.pval <= 1, "GD", "nGD")
  }

  return(GD.status)
}




#' genome.doub.timing
#' 
#' Function to assess the timing of GD relative to the genome loss. Some genotypes are happened before GD (AA or AAA) whereas the other are after GD (AAB and AB)
#'
#' @param sample TCGA sample identifier
#' @param seg.mat.minor segmented minor allele copy number matrix. segmented matrix with minor allele (e.g. seg.mat.LOH). columns should be as follows: c("Sample","Chrom","Start","End","Num.probes","val")
#' @param seg.mat.copy segmented total copy number matrix. segmented total copy number matrix (columns as above)
#' @param loss.level The cnv loss types to use. 2 or 3. If loss.level == 2, genotypes, AA and AB are used, if loss.level == 3, genotypes: AA, AB, AAB and AAA are used.
#' 
#' @details 
#' According to the code of clonality.estimation(), "val" means "cn". the function uses the limma weighted.median function
#' 
#' @return
#' the function returns a GD.timing dataframe and the information of arm levels.
#' 
#' @export
#' 
#' @importFrom magrittr %>%
#' @import dplyr
#'
#' @examples
#' genome.doub.timing(sample, seg.mat.minor, seg.mat.copy)
#'

genome.doub.timing <- function(sample, seg.mat.minor, seg.mat.copy,
                               loss.level = 3
                               ) {
  if(loss.level == 2){
    message("The genotype AA and AB are used")
  }else{
    message("The genotype AA, AB, AAA and AAB are used")
  }

  # define expected chr names
  chr.names <- c(
    "1", "1.5", "2", "2.5", "3", "3.5", "4", "4.5", "5", "5.5", "6", "6.5", "7", "7.5", "8", "8.5", "9",
    "9.5", "10", "10.5", "11", "11.5", "12", "12.5", "13.5", "14.5", "15.5", "16", "16.5", "17",
    "17.5", "18", "18.5", "19", "19.5", "20", "20.5", "21.5", "22.5"
  )
  
  # Remove other samples:
  sub.minor <- subset(seg.mat.minor, seg.mat.minor[, 1] == sample)
  sub.major <- subset(seg.mat.copy, seg.mat.copy[, 1] == sample)
  
  genotype = function(A, B){
    if(A == 1 & B == 1){
      "AB"
    }else if(A == 2 & B == 1){
      "AAB"
    }else if(A == 2 & B == 0){
      "AA"
    }else if(A == 3 & B == 0){
      "AAA"
    }else{
      "Other"
    }
  }
  
  timing = function(genotype, loss.level = loss.level){
  
    time = rep(NA, length(genotype))
    
    if(loss.level == 2){
      
      for(i in 1:length(genotype)){
        if( genotype[i] %in% c("AA") ){
          time[i] =  "Before"
        }else if( genotype[i] %in% c("AB")){
          time[i] = "After"
        }else{
          time[i] = "Unknown"
        }
      }
      
    }else{
      for(i in 1:length(genotype)){
        if( genotype[i] %in% c("AA","AAA") ){
          time[i] =  "Before"
        }else if( genotype[i] %in% c("AB","AAB")){
          time[i] = "After"
        }else{
          time[i] = "Unknown"
        }
      }
    }
    
    time
  }
  
  #get segment levels.
  sub.mat = as.data.frame(sub.major) %>%
    dplyr::rename(CNt = val) %>%
    left_join( as.data.frame(sub.minor) %>%
                dplyr::rename(Minor = val) ) %>%
    mutate(
      Start = as.numeric(Start),
      End = as.numeric(End),
      CNt = as.numeric(CNt),
      Minor = as.numeric(Minor),
      Major = CNt - Minor) %>%
    rowwise() %>%
    mutate(genotype = genotype(Major, Minor)) %>%
    mutate(time = timing(genotype, loss.level))
  
  sub.mat.summ = sub.mat %>%
    group_by(time) %>%
    summarise(len = sum(End - Start)) %>%
    mutate(seg.prop = len/sum(len))%>%
    as.data.frame()
  
  
  #Get arms levels
  sub.mat.arms = sub.mat %>%
    group_by(Chrom) %>%
    summarise(
      CNt = limma::weighted.median(CNt, w = End - Start,  na.rm = TRUE),
      Minor = limma::weighted.median(Minor, w = End - Start,  na.rm = TRUE),
      Major = CNt - Minor,
      genotype = genotype(Major, Minor)
    ) %>%
    mutate(time = timing(genotype, loss.level))
    
  sub.mat.arms.summ = sub.mat.arms %>%
    group_by(time) %>%
    summarise(num = n()) %>%
    mutate(arm.prop = num/sum(num)) %>%
    as.data.frame()
    
  sub.mat.summ %>%
    left_join(sub.mat.arms.summ)
 
  GD.timing = data.frame(
    before = c(sub.mat.summ[sub.mat.summ$time == "Before", "seg.prop"], 
               sub.mat.arms.summ[sub.mat.summ$time == "Before", "arm.prop"]),
    after = c(sub.mat.summ[sub.mat.summ$time == "After", "seg.prop"],
              sub.mat.arms.summ[sub.mat.summ$time == "After", "arm.prop"]),
    source = c("segments","arms"),
    sample = sample
  ) %>%
    mutate(
      before = round(before, 5),
      after = round(after, 5)
    )
  
  sub.mat.arms = sub.mat.arms %>%
    mutate(Chrom = factor(Chrom, levels = chr.names )) %>%
    arrange(Chrom) %>%
    mutate(sample = sample)
  
  return(
    list(
    GD.timing = GD.timing,
    sub.mat.arms = sub.mat.arms
    )
  )
  
}













###########################################
###########################################
## get seg.mat.copy ###################
###########################################

#' get.seg.mat.arm
#' 
#' @export

get.seg.mat.arm <- function(seg.mat.copy) {
  data(centromere)
  # "seg.mat.copy.arm" is a vector. But after rbind(), it returns to a data.frame.
  seg.mat.copy.arm <- c()

  for (sample in unique(seg.mat.copy[, 1])) {
    # "sample" is a TSB
    # "sub" is a subset data.frame (?) of "sample"
    sub <- seg.mat.copy[seg.mat.copy[, 1] == sample, ]
    sub <- subset(seg.mat.copy, seg.mat.copy[, 1] == sample)
    sub.seg <- c()

    for (chr in as.character(unique(sub[, 2]))) {
      # print(chr)
      chr.sub <- sub[sub[, 2] == chr, , drop = FALSE]

      # identify subset of segments that are on chr1 or chr1.5
      # "chr1.5" means the q arm of chr1.
      # "start" < centromere start:
      chr.p <- chr.sub[which(as.numeric(chr.sub[, 3]) < centromere[chr, 2]), , drop = FALSE]
      if (nrow(chr.p) != 0) {
        # If "end" > centromere "start", split the row into two rows,
        # by changing "end" into the "start" or "end" of centromere.
        chr.p[as.numeric(chr.p[, 4]) > centromere[chr, 2], 4] <- round(centromere[as.character(chr), 2])
        # In centromere, V2 == V3, so useing "start" or "end" has no difference.
      }

      chr.q <- subset(chr.sub, as.numeric(chr.sub[, 4]) > centromere[chr, 2])
      if (nrow(chr.q) != 0) {
        # Add 1 to the new "start" location.
        chr.q[as.numeric(chr.q[, 3]) < centromere[chr, 2], 3] <- as.numeric(centromere[as.character(chr), 2]) + c(1)
        chr.q[, 2] <- paste(chr.q[, 2], ".5", sep = "")
      }

      chr.seg <- rbind(chr.p, chr.q)
      sub.seg <- rbind(sub.seg, chr.seg)
    }

    seg.mat.copy.arm <- rbind(seg.mat.copy.arm, sub.seg)
  }

  chr.names <- c(
    "1", "1.5", "2", "2.5", "3", "3.5", "4", "4.5", "5", "5.5", "6", "6.5", "7", "7.5", "8", "8.5", "9",
    "9.5", "10", "10.5", "11", "11.5", "12", "12.5", "13.5", "14.5", "15.5", "16", "16.5", "17",
    "17.5", "18", "18.5", "19", "19.5", "20", "20.5", "21.5", "22.5"
  )
  # Why no 21, 15, 22, 13, 14? 
  #see https://www.sciencedirect.com/topics/medicine-and-dentistry/chromosome-identification
  seg.mat.copy.arm[seg.mat.copy.arm[, 2] == 21, 2] <- "21.5"
  seg.mat.copy.arm[seg.mat.copy.arm[, 2] == 15, 2] <- "15.5"
  seg.mat.copy.arm[seg.mat.copy.arm[, 2] == 22, 2] <- "22.5"
  seg.mat.copy.arm[seg.mat.copy.arm[, 2] == 13, 2] <- "13.5"
  seg.mat.copy.arm[seg.mat.copy.arm[, 2] == 14, 2] <- "14.5"

  if (length(unique(seg.mat.copy.arm[, 2])[which(!unique(seg.mat.copy.arm[, 2]) %in% chr.names)]) != 0) {
    stop("Cannot fit chromosome arms")
  }

  return(seg.mat.copy.arm)
}
