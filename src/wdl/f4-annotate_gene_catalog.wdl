version 1.0

workflow annotate_gene_catalogue {
    input{
        Array[File] gene_clusters_split
        Int num_threads = 4 
    }
    
    scatter (gene_shard in gene_clusters_split) {

        call annotate_eggnog {
            input:
            gene_catalogue=gene_shard,
            eggnog_threads=num_threads
        }

        call annotate_deepfri {
            input:     
            gene_catalogue=gene_shard
        }
    }
}

task annotate_eggnog {
    input {
    File gene_catalogue
    Int eggnog_threads
    }
    
    command {
        # TODO: mount in submit script 
        

        python3.9 /app/eggnog-mapper-2.1.6/emapper.py \
            --itype CDS \
            --cpu ${eggnog_threads} \
            -i ${gene_catalogue} \
            --output nr-eggnog \
            --output_dir . \
            -m diamond \
            -d none \
            --tax_scope auto \
            --go_evidence non-electronic \
            --target_orthologs all \
            --seed_ortholog_evalue 0.001 \
            --seed_ortholog_score 60 \
            --query_cover 20 \
            --subject_cover 0 \
            --translate \
            --override

    }

    output {
        File eggnog_annotations = "nr-eggnog.emapper.annotations"
        File eggnog_seed_orthologs = "nr-eggnog.emapper.seed_orthologs"
    }

    runtime {
        docker: "crusher083/eggnog-mapper@sha256:79301af19fc7af2b125297976674e88a5b4149e1867977938510704d1198f70f"
        maxRetries: 1
    }
}

task annotate_deepfri {
    input {
    File gene_catalogue
    } 
    
    command {
        /bin/python3 /app/scripts/cromwell_process_fasta.py -i ${gene_catalogue} -o deepfri_annotations.csv -m /app --translate
    }

    output {
        File deepfri_out = "deepfri_annotations.csv"
    }

    runtime {
        docker: "crusher083/deepfri_seq@sha256:7d65c3e0d58a6cc38bd55f703a337910499b3d5d76a7330480a6cc391d09ffb6"
        maxRetries: 1
    }
}

